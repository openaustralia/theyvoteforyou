# frozen_string_literal: true

# Receives Postal's delivery webhooks and suppresses addresses that hard-bounce. Same route as Planning Alerts.
# https://docs.postalserver.io/developer/webhooks
#
# An API controller, so there is no session or request forgery check: Postal is not a browser.
class PostalController < ActionController::API
  HARD_FAILURE_EVENTS = %w[MessageDeliveryFailed MessageBounced].freeze
  TAGS_WE_SET = [MailKind::ALERT, MailKind::CONFIRMATION, MailKind::PASSWORD, MailKind::NOTICE].freeze

  def event
    failure = signature_failure_status(request.raw_post)
    return head failure if failure

    body = JSON.parse(request.raw_post)
    event = body["event"]
    payload = body["payload"]
    # Delayed, held and every other event are accepted and ignored. Postal keeps retrying soft failures itself.
    return head :ok unless HARD_FAILURE_EVENTS.include?(event) && payload.is_a?(Hash)

    suppress_if_hard_bounce(event, payload)
    head :ok
  end

  private

  # A bounce report wraps the message that bounced in original_message.
  def suppress_if_hard_bounce(event, payload)
    message = payload[event == "MessageBounced" ? "original_message" : "message"]
    recipient = message.is_a?(Hash) ? message["to"] : nil
    # Mail without a tag we set isn't ours to act on.
    return log(event, "ignored: untagged") if recipient.blank? || TAGS_WE_SET.exclude?(message["tag"])
    return log(event, "ignored: refusal blames our server") if refusal_blames_sender?(event, payload)

    EmailSuppression.suppress!(recipient, reason: :hard_bounce, postal_event: event, reply: payload["output"])
    log(event, "suppressed")
  end

  def refusal_blames_sender?(event, payload)
    event == "MessageDeliveryFailed" && PostalWebhook::BounceRule.blames_sender?(payload["output"])
  end

  # Event type and outcome only, never an address.
  def log(event, outcome)
    Rails.logger.info("Postal #{event}: #{outcome}")
  end

  # X-Postal-Signature-256 holds a base64 RSA-SHA256 signature of the raw body, made with Postal's installation-wide
  # key. We check it against every key Postal currently publishes, so a rotation needs no change here.
  #
  # Returns nil when properly signed, otherwise the status to respond with. A bad signature gets 403 and the event is
  # gone for good. Being unable to reach the keys is different: we can't tell whether the request is genuine, so 503
  # asks Postal to retry (about 36 minutes of backoffs) instead of dropping a real event.
  def signature_failure_status(raw_post)
    signature = request.headers["X-Postal-Signature-256"]
    # Checked before the keys are fetched, so an unsigned request costs no outbound request.
    return :forbidden if signature.blank?

    keys = PostalWebhook::SigningKeys.call
    return :service_unavailable if keys.nil?

    decoded = Base64.decode64(signature)
    keys.any? { |key| key.verify(OpenSSL::Digest.new("SHA256"), decoded, raw_post) } ? nil : :forbidden
  end
end
