# frozen_string_literal: true

module PostalWebhook
  # Decides whether a permanent delivery failure says anything about the recipient's address. Shared by the webhook and
  # the one-off import of past failures, so the two can't drift apart.
  module BounceRule
    # The receiving server's reply starts with a 5.7.x enhanced status code when it has refused us for a policy or
    # reputation reason, such as a block on our sending IP address. That says nothing about whether the address works.
    # https://www.rfc-editor.org/rfc/rfc3463
    SENDER_SIDE_REFUSAL = /\A\d{3}[ -]5\.7\.\d+/

    def self.blames_sender?(reply)
      SENDER_SIDE_REFUSAL.match?(reply.to_s)
    end
  end
end
