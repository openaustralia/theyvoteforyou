# frozen_string_literal: true

require "spec_helper"

# Postal's published keys are served through WebMock, so nothing contacts Postal.
RSpec.describe "Postal delivery webhook", type: :request do
  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:jwks_url) { Rails.configuration.x.postal_jwks_url }
  let(:recipient) { "someone@example.org" }

  def b64(integer)
    Base64.urlsafe_encode64(integer.to_s(2), padding: false)
  end

  def jwk(key, **extra)
    { kty: "RSA", n: b64(key.n), e: b64(key.e) }.merge(extra)
  end

  def stub_jwks(*jwks, status: 200)
    stub_request(:get, jwks_url).to_return(status: status, body: { keys: jwks }.to_json)
  end

  def sign(body, key: private_key)
    Base64.strict_encode64(key.sign(OpenSSL::Digest.new("SHA256"), body))
  end

  def post_event(body, signature: sign(body))
    headers = { "CONTENT_TYPE" => "application/json" }
    headers["X-Postal-Signature-256"] = signature if signature
    post "/postal/event", params: body, headers: headers
  end

  def message(tag: "alert", to: recipient)
    { id: 1, token: "abc", direction: "outgoing", to: to, from: "contact@theyvoteforyou.org.au", tag: tag }
  end

  def status_event(event: "MessageDeliveryFailed", output: "550 5.1.1 No such user", tag: "alert", to: recipient)
    { event: event, uuid: "0f6f76ec", payload: { status: "HardFail", details: "Hard fail", output: output,
                                                 message: message(tag: tag, to: to) } }.to_json
  end

  def bounce_event(tag: "alert", to: recipient)
    { event: "MessageBounced", uuid: "0f6f76ed",
      payload: { original_message: message(tag: tag, to: to), bounce: { id: 2, direction: "incoming", tag: nil } } }.to_json
  end

  before { stub_jwks(jwk(private_key)) }

  describe "a hard failure" do
    it "suppresses the address and answers 200" do
      post_event(status_event)

      expect(response).to have_http_status(:ok)
      suppression = EmailSuppression.active.sole
      expect(suppression).to have_attributes(address: recipient, reason: "hard_bounce",
                                             postal_event: "MessageDeliveryFailed",
                                             reply_excerpt: "550 5.1.1 No such user")
    end

    it "suppresses a bounce report that arrives later, taking the address from the original message" do
      post_event(bounce_event)

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.active.sole).to have_attributes(address: recipient, postal_event: "MessageBounced")
    end

    it "suppresses when the receiving server gave no reply" do
      post_event(status_event(output: ""))

      expect(EmailSuppression.suppressed?(recipient)).to be(true)
    end

    it "normalises the address" do
      post_event(status_event(to: "  Someone@Example.ORG "))

      expect(EmailSuppression.active.sole.address).to eq(recipient)
    end

    it "suppresses for mail of any kind we tagged" do
      post_event(status_event(tag: "confirmation"))

      expect(EmailSuppression.suppressed?(recipient)).to be(true)
    end

    it "changes nothing on a repeated report" do
      2.times { post_event(status_event) }
      post_event(bounce_event)

      expect(EmailSuppression.count).to eq(1)
    end

    it "makes a fresh suppression when it bounces again after a lift" do
      post_event(status_event)
      EmailSuppression.lift!(recipient)
      post_event(status_event)

      expect(EmailSuppression.count).to eq(2)
      expect(EmailSuppression.active.count).to eq(1)
    end
  end

  describe "events that suppress nothing" do
    ["550 5.7.1 Our system has detected that this message is suspicious", "550-5.7.26 Unauthenticated sender"].each do |reply|
      it "leaves a refusal that blames our server alone (#{reply[0, 12]}...)" do
        post_event(status_event(output: reply))

        expect(response).to have_http_status(:ok)
        expect(EmailSuppression.count).to eq(0)
      end
    end

    %w[MessageDelayed MessageHeld MessageSent SomethingNew].each do |event|
      it "ignores #{event} with a 200" do
        post_event(status_event(event: event))

        expect(response).to have_http_status(:ok)
        expect(EmailSuppression.count).to eq(0)
      end
    end

    it "ignores mail without a tag" do
      post_event(status_event(tag: nil))

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.count).to eq(0)
    end

    it "ignores mail with a tag we don't set" do
      post_event(status_event(tag: "comment-12"))

      expect(EmailSuppression.count).to eq(0)
    end

    it "ignores a bounce report for untagged mail" do
      post_event(bounce_event(tag: nil))

      expect(EmailSuppression.count).to eq(0)
    end
  end

  describe "signatures" do
    it "refuses a request with no signature, before fetching any key" do
      post_event(status_event, signature: nil)

      expect(response).to have_http_status(:forbidden)
      expect(a_request(:get, jwks_url)).not_to have_been_made
      expect(EmailSuppression.count).to eq(0)
    end

    it "refuses a signature that doesn't verify" do
      post_event(status_event, signature: sign("something else entirely"))

      expect(response).to have_http_status(:forbidden)
      expect(EmailSuppression.count).to eq(0)
    end

    it "refuses a signature made with a different key" do
      post_event(status_event(output: ""), signature: sign(status_event(output: ""), key: OpenSSL::PKey::RSA.new(2048)))

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses a signature that isn't base64" do
      post_event(status_event, signature: "!!! not base64 !!!")

      expect(response).to have_http_status(:forbidden)
    end

    it "accepts a signature from any one of the keys Postal publishes" do
      stub_jwks(jwk(OpenSSL::PKey::RSA.new(2048)), jwk(private_key))

      post_event(status_event)

      expect(EmailSuppression.suppressed?(recipient)).to be(true)
    end

    it "accepts a key with use sig, and never uses an encryption key or a non-RSA key" do
      stub_jwks(jwk(private_key, use: "sig"))
      post_event(status_event)
      expect(response).to have_http_status(:ok)

      stub_jwks(jwk(private_key, use: "enc"), { kty: "oct", k: "c2VjcmV0" }, jwk(OpenSSL::PKey::RSA.new(2048)))
      post_event(status_event)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "when the published keys can't be used" do
    it "asks Postal to retry when the keys can't be fetched" do
      stub_request(:get, jwks_url).to_timeout

      post_event(status_event)

      expect(response).to have_http_status(:service_unavailable)
      expect(EmailSuppression.count).to eq(0)
    end

    it "asks Postal to retry when Postal answers with an error" do
      stub_jwks(status: 500)

      post_event(status_event)

      expect(response).to have_http_status(:service_unavailable)
    end

    it "asks Postal to retry when the key set is malformed" do
      stub_request(:get, jwks_url).to_return(status: 200, body: "not json")

      post_event(status_event)

      expect(response).to have_http_status(:service_unavailable)
    end

    ["null", "true", "[]", '"keys"', '{"keys": "none"}', '{"keys": null}'].each do |body|
      it "asks Postal to retry, rather than failing, when the key set is valid JSON but not a key set (#{body})" do
        stub_request(:get, jwks_url).to_return(status: 200, body: body)

        post_event(status_event)

        expect(response).to have_http_status(:service_unavailable)
      end
    end

    it "caches an unusable key set too, so it isn't fetched again for every webhook" do
      cache = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(cache)
      stub_request(:get, jwks_url).to_return(status: 200, body: "null")

      3.times { post_event(status_event) }

      expect(a_request(:get, jwks_url)).to have_been_made.once
    end

    it "asks Postal to retry when the key set has no usable key" do
      stub_jwks({ kty: "RSA", n: 1, e: 2 }, { kty: "oct", k: "c2VjcmV0" })

      post_event(status_event)

      expect(response).to have_http_status(:service_unavailable)
    end
  end

  describe "fetching the keys" do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(cache) }

    it "caches them, so a burst of webhooks fetches once" do
      3.times { post_event(status_event) }

      expect(a_request(:get, jwks_url)).to have_been_made.once
    end

    it "caches a failure too, so an outage isn't one outbound request per webhook" do
      stub_request(:get, jwks_url).to_timeout

      3.times { post_event(status_event) }

      expect(a_request(:get, jwks_url)).to have_been_made.once
    end
  end

  it "writes the event and outcome to the log, and no address" do
    logged = []
    allow(Rails.logger).to receive(:info) { |message = nil, &block| logged << (message || block&.call).to_s }

    post_event(status_event)

    expect(logged).to include("Postal MessageDeliveryFailed: suppressed")
    expect(logged.join("\n")).not_to include(recipient)
  end
end
