# frozen_string_literal: true

module PostalWebhook
  # The public keys Postal publishes for the key it signs webhooks with. Postal signs with one installation-wide key and
  # publishes the matching public key as a JWK Set at a well-known address, so we check against whatever it publishes
  # now rather than holding a copy. A key rotation on the Postal server then needs no change here.
  # https://docs.postalserver.io/developer/webhooks and https://www.rfc-editor.org/rfc/rfc7517
  #
  # Mirrors Planning Alerts' PostalSigningKeysService, but builds the RSA key by hand so this app needs no JWT gem.
  class SigningKeys
    # Postal gives up on a webhook after 5 seconds and this runs inside that request, so a slower fetch is no use.
    HTTP_TIMEOUT = 2

    CACHE_KEY = "postal_webhook/signing_keys/v1"

    # Long enough that a burst of webhooks isn't a fetch each, short enough that a key rotation heals inside Postal's
    # retries (2, 3, 6, 10 and 15 minute backoffs, about 36 minutes). Failures are cached too, deliberately: that is
    # what stops an outage becoming one outbound request per inbound webhook on an endpoint anyone can post to.
    CACHE_TTL = 15.minutes

    # While one request refreshes an expired entry, others keep getting the stale copy instead of fetching.
    RACE_CONDITION_TTL = 5.seconds

    REFRESH_LIMIT_KEY = "postal_webhook/signing_keys/v1/refreshed"

    # The most often refresh may fetch the keys, whoever is asking.
    MIN_REFRESH_INTERVAL = 1.minute

    # Returns the RSA public keys, or nil if they can't be determined.
    def self.call
      pems = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL, race_condition_ttl: RACE_CONDITION_TTL) { fetch_pems }
      pems&.map { |pem| OpenSSL::PKey::RSA.new(pem) }
    end

    # For a signature the cached keys don't verify. Postal may have started signing with a new key, which the cache won't
    # show for up to CACHE_TTL. Fetches now and replaces the cached keys, but at most once per MIN_REFRESH_INTERVAL, so
    # signatures that don't verify can't make one outbound request each. Returns the keys, or nil if the refresh was
    # skipped or the keys can't be determined. The cached keys are kept when the fetch fails.
    def self.refresh
      return unless Rails.cache.write(REFRESH_LIMIT_KEY, true, expires_in: MIN_REFRESH_INTERVAL, unless_exist: true)

      pems = fetch_pems
      return if pems.nil?

      Rails.cache.write(CACHE_KEY, pems, expires_in: CACHE_TTL)
      pems.map { |pem| OpenSSL::PKey::RSA.new(pem) }
    end

    # PEM strings rather than key objects, because the production cache is memcached and what we store has to survive
    # Marshal. Network failures and a malformed body degrade to nil ("can't check this signature") rather than a 500.
    def self.fetch_pems
      response = HTTParty.get(Rails.configuration.x.postal_jwks_url, timeout: HTTP_TIMEOUT)
      return nil unless response.code == 200

      parsed = JSON.parse(response.body)
      keys = parsed["keys"] if parsed.is_a?(Hash)
      keys.filter_map { |jwk| signing_pem(jwk) }.presence if keys.is_a?(Array)
    rescue Timeout::Error, SocketError, SystemCallError, EOFError, Net::ProtocolError, Net::HTTPBadResponse,
           Net::HTTPHeaderSyntaxError, JSON::ParserError, TypeError, ArgumentError, OpenSSL::OpenSSLError
      nil
    end

    # Only RSA keys marked for signatures, or with no usage stated ("use" is optional in RFC 7517). Never encryption keys.
    def self.signing_pem(jwk)
      return unless jwk.is_a?(Hash) && jwk["kty"] == "RSA" && [nil, "sig"].include?(jwk["use"])
      return unless jwk["n"].is_a?(String) && jwk["e"].is_a?(String)

      modulus = OpenSSL::BN.new(Base64.urlsafe_decode64(jwk["n"]), 2)
      exponent = OpenSSL::BN.new(Base64.urlsafe_decode64(jwk["e"]), 2)
      sequence = OpenSSL::ASN1::Sequence([OpenSSL::ASN1::Integer(modulus), OpenSSL::ASN1::Integer(exponent)])
      OpenSSL::PKey::RSA.new(sequence.to_der).to_pem
    end
    private_class_method :fetch_pems, :signing_pem
  end
end
