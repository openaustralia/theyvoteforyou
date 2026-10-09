# frozen_string_literal: true

require "csv"

# One-off clean-up that suppresses addresses Postal has already hard-failed, so the damage stops before the webhook is
# switched on. Applies the same rule as the webhook (PostalWebhook::BounceRule), and additionally skips rows with no
# reply from the receiving server, because a failure with no reply (for example Postal's own outbound spam check) says
# nothing about the address.
#
# The input is a CSV export from the Postal server's history with a header row. Columns (names are case-insensitive):
#   address (or rcpt_to)   the recipient
#   output (or reply)      the receiving server's reply, exactly as Postal stored it
#   date (or timestamp)    optional, when the most recent hard fail happened
#
# The file is real personal data: keep it out of the repository (tmp/ is ignored), tickets, chat and AI conversations.
# Safe to run twice. Returns counts only so the output can be shared without exposing an address.
class EmailSuppressionImport
  Result = Struct.new(:suppressed, :already_suppressed, :skipped_refusal_blaming_our_server, :skipped_no_reply,
                      :skipped_no_address, keyword_init: true)

  def self.call(path)
    new.call(path)
  end

  def call(path)
    result = Result.new(suppressed: 0, already_suppressed: 0, skipped_refusal_blaming_our_server: 0,
                        skipped_no_reply: 0, skipped_no_address: 0)
    CSV.foreach(path, headers: true, header_converters: ->(header) { header.to_s.strip.downcase }) do |row|
      result[outcome_for(row)] += 1
    end
    result
  end

  private

  def outcome_for(row)
    address = row["address"] || row["rcpt_to"]
    reply = row["output"] || row["reply"]
    return :skipped_no_address if address.blank?
    return :skipped_no_reply if reply.blank?
    return :skipped_refusal_blaming_our_server if PostalWebhook::BounceRule.blames_sender?(reply)
    return :already_suppressed if EmailSuppression.suppressed?(address)

    EmailSuppression.suppress!(address, reason: :imported_from_postal, reply: reply, at: failed_at(row))
    :suppressed
  end

  # When the most recent hard fail happened, so a person's notice says since when their emails have been returning.
  def failed_at(row)
    Time.zone.parse((row["date"] || row["timestamp"]).to_s) || Time.current
  rescue ArgumentError
    Time.current
  end
end
