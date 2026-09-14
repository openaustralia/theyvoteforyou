# frozen_string_literal: true

require "spec_helper"

describe AltchaChallenge do
  # A real memory store, because Rails.cache is a null store in test where every write succeeds
  # and the replay guard would silently pass.
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  # Solving a challenge at production difficulty takes about a tenth of a second, which is fine
  # once but wasteful thirteen times over. Most examples use a deliberately trivial challenge and
  # only exercise the checking; the production numbers get their own example below.
  def easy_challenge(scope: "registrations", expires_at: 10.minutes.from_now)
    Altcha::V2.create_challenge(
      Altcha::V2::CreateChallengeOptions.new(
        algorithm: described_class::ALGORITHM,
        cost: 1,
        counter: 3,
        expires_at: expires_at,
        data: scope,
        hmac_signature_secret: described_class.send(:signature_secret),
        hmac_key_signature_secret: described_class.send(:key_signature_secret)
      )
    )
  end

  # Always build payloads through Payload#to_json. The solution key is "derivedKey" in camelCase
  # and hand-rolling that JSON is an easy way to write a passing spec for broken code.
  def solved(challenge)
    Base64.strict_encode64(
      Altcha::V2::Payload.new(
        challenge: challenge, solution: Altcha::V2.solve_challenge(challenge)
      ).to_json
    )
  end

  def outcome_for(encoded, scope: "registrations", store: cache)
    described_class.verify(encoded, scope: scope, cache: store).outcome
  end

  describe ".issue" do
    it "signs the challenge so it cannot be edited in flight" do
      expect(described_class.issue(scope: "registrations").signature).to be_present
    end

    it "records which form the challenge belongs to" do
      expect(described_class.issue(scope: "passwords").parameters.data).to eq "passwords"
    end

    it "expires the challenge" do
      expect(described_class.issue(scope: "registrations").parameters.expires_at)
        .to be_within(5.seconds.to_i).of(described_class::EXPIRES_IN.from_now.to_i)
    end
  end

  describe ".verify" do
    context "with an answer solved at the real difficulty" do
      it "verifies" do
        challenge = described_class.issue(scope: "registrations")
        expect(outcome_for(solved(challenge))).to eq :verified
      end
    end

    it "verifies a correct answer" do
      expect(outcome_for(solved(easy_challenge))).to eq :verified
    end

    it "rejects an answer that has already been spent" do
      encoded = solved(easy_challenge)
      expect(outcome_for(encoded)).to eq :verified
      expect(outcome_for(encoded)).to eq :replayed
    end

    it "treats a missing answer as missing rather than raising" do
      expect(outcome_for(nil)).to eq :missing
      expect(outcome_for("")).to eq :missing
    end

    it "treats an unreadable answer as unreadable rather than raising" do
      expect(outcome_for("!!! not base64 !!!")).to eq :unreadable
      expect(outcome_for(Base64.strict_encode64("{}"))).to eq :unreadable
      expect(outcome_for(Base64.strict_encode64('{"challenge":'))).to eq :unreadable
    end

    it "rejects an expired challenge" do
      expect(outcome_for(solved(easy_challenge(expires_at: 1.minute.ago)))).to eq :expired
    end

    it "rejects an answer solved for a different form" do
      expect(outcome_for(solved(easy_challenge(scope: "registrations")), scope: "passwords"))
        .to eq :wrong_form
    end

    it "rejects a challenge whose form has been edited, because the signature covers it" do
      tampered = JSON.parse(Base64.decode64(solved(easy_challenge)))
      tampered["challenge"]["parameters"]["data"] = "passwords"
      expect(outcome_for(Base64.strict_encode64(tampered.to_json), scope: "passwords"))
        .to eq :tampered
    end

    it "rejects a forged signature" do
      forged = JSON.parse(Base64.decode64(solved(easy_challenge)))
      forged["challenge"]["signature"] = "0" * 64
      expect(outcome_for(Base64.strict_encode64(forged.to_json))).to eq :tampered
    end

    it "rejects a wrong answer" do
      wrong = JSON.parse(Base64.decode64(solved(easy_challenge)))
      wrong["solution"]["derivedKey"] = "ab" * 32
      expect(outcome_for(Base64.strict_encode64(wrong.to_json))).to eq :unsolved
    end

    # The fast verification path authenticates the derived key rather than the counter that
    # produced it. That is sound, because producing the right key is the work, but it surprises
    # people reading the code so it is pinned here.
    it "accepts a right answer submitted with the wrong counter" do
      relabelled = JSON.parse(Base64.decode64(solved(easy_challenge)))
      relabelled["solution"]["counter"] = relabelled["solution"]["counter"].to_i + 1
      expect(outcome_for(Base64.strict_encode64(relabelled.to_json))).to eq :verified
    end
  end

  describe "difficulty" do
    # The easy challenges above would hide a bad constant, so assert the real ones separately.
    it "asks the browser for enough work to make bulk submission expensive" do
      expect(described_class::COST).to be >= 1_000
      expect(described_class::COUNTER_RANGE.min).to be >= 100
    end

    it "keeps a spent answer marked for longer than the challenge itself lives" do
      expect(described_class::REPLAY_WINDOW).to be > described_class::EXPIRES_IN
    end
  end
end
