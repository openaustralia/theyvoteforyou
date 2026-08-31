# frozen_string_literal: true

require "altcha"
require "base64"

# Issues and checks ALTCHA (https://altcha.org) proof-of-work challenges for the anonymous forms.
# See docs/adr/0004-altcha-proof-of-work-on-anonymous-forms.md for why this exists, why the numbers
# below are what they are, and what it costs people without JavaScript.
#
# The shape of it: we put a challenge in the page whose parameters we have signed with an HMAC, and
# the browser has to derive a key matching the prefix we signed. Because the prefix is the whole
# first half of the derived key there is no shortcut, so the browser works up from counter 0 to the
# counter we picked, doing one key derivation each step, while we do exactly one to set the
# challenge and three HMACs to check the answer.
#
# Nothing about a challenge is stored until it is solved. The signature covers every parameter, so
# a challenge cannot be edited in flight, and the two secrets come from secret_key_base, so there
# is no new credential to manage and this works in development and test where there is no
# credentials store.
#
# This speaks the v2 challenge protocol, which is what widget v3
# (vendor/assets/javascripts/altcha.js) speaks. Widget v2 and earlier speak v1 and will not verify.
class AltchaChallenge
  # PBKDF2/SHA-256 runs natively in the browser through WebCrypto and needs no extra gem here.
  # SCRYPT is hard on phones and ARGON2ID would mean a native extension on the server.
  ALGORITHM = "PBKDF2/SHA-256"

  # Iterations per key derivation. Also bounds our own cost: we run one derivation to issue a
  # challenge, and none at all to check an answer.
  COST = 2_000

  # The difficulty dial. The browser does about this many derivations, so the work is linear in
  # this number. Treat these as a starting point and confirm real solve times on a real phone
  # during the log-only phase of the rollout rather than trusting the arithmetic.
  COUNTER_RANGE = (100..300)

  # Long enough that a slowly filled in form still works. The challenge is embedded in the page, so
  # unlike a challenge fetched from an endpoint it cannot be refreshed in place; a submission after
  # this re-renders the form with a fresh challenge and the retry works.
  EXPIRES_IN = 30.minutes

  # Outlives the challenge, so a solved answer cannot be replayed in the gap between the marker
  # expiring and the challenge expiring.
  REPLAY_WINDOW = EXPIRES_IN + 5.minutes

  # Why a check failed. Worth distinguishing: during the log-only phase "no answer at all" and
  # "solved it wrong" say very different things about who is being turned away.
  Result = Data.define(:outcome) do
    def verified? = outcome == :verified
  end

  class << self
    # scope ties a challenge to one form, so an answer solved on the sign up page cannot be spent
    # against the password reset form. It is covered by the signature, so it cannot be edited.
    def issue(scope:)
      Altcha::V2.create_challenge(
        Altcha::V2::CreateChallengeOptions.new(
          algorithm: ALGORITHM,
          cost: COST,
          counter: rand(COUNTER_RANGE),
          expires_at: EXPIRES_IN.from_now,
          data: scope,
          hmac_signature_secret: signature_secret,
          hmac_key_signature_secret: key_signature_secret
        )
      )
    end

    # encoded is the base64 blob the widget puts in its hidden field.
    #
    # cache is injectable because Rails.cache is a null store under test, where every write
    # succeeds and the replay guard would silently pass. The unit spec passes a real memory store.
    def verify(encoded, scope:, cache: Rails.cache)
      return Result.new(outcome: :missing) if encoded.blank?

      payload = parse(encoded)
      return Result.new(outcome: :unreadable) if payload.nil?

      result = Altcha::V2.verify_solution(
        payload.challenge,
        payload.solution,
        hmac_signature_secret: signature_secret,
        hmac_key_signature_secret: key_signature_secret
      )
      return Result.new(outcome: :expired) if result.expired
      return Result.new(outcome: :tampered) if result.invalid_signature
      return Result.new(outcome: :unsolved) unless result.verified

      # Only meaningful once the signature has verified, so it is checked after, not before.
      return Result.new(outcome: :wrong_form) unless payload.challenge.parameters.data == scope
      return Result.new(outcome: :replayed) unless claim(payload.challenge.signature, cache)

      Result.new(outcome: :verified)
    end

    private

    def parse(encoded)
      Altcha::V2::Payload.from_json(Base64.decode64(encoded))
    rescue StandardError
      nil
    end

    # Marks a solved challenge as spent. False means it already was.
    #
    # This has to run after verify_solution, or anyone could fill the cache with invented
    # signatures. Without it, one solved challenge buys half an hour of resubmission, which on the
    # password reset form means half an hour of sending reset emails on our mail reputation.
    def claim(signature, cache)
      cache.write("altcha/spent/#{signature}", true, expires_in: REPLAY_WINDOW, unless_exist: true)
    end

    # generate_key is itself a PBKDF2 run, and the key generator is only guaranteed to cache in
    # some environments, so hold onto the result rather than paying for it on every form render.
    def signature_secret
      @signature_secret ||= Rails.application.key_generator.generate_key("altcha challenge signature", 32)
    end

    def key_signature_secret
      @key_signature_secret ||= Rails.application.key_generator.generate_key("altcha key signature", 32)
    end
  end
end
