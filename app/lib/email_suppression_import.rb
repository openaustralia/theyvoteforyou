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
# The export must hold hard failures only: this doesn't check the event, so a row for mail that was delivered, or that
# soft-failed, would suppress a working address.
#
# The file is real personal data: keep it out of the repository (tmp/ is ignored), tickets, chat and AI conversations.
# Safe to run twice. Returns counts only so the output can be shared without exposing an address.
class EmailSuppressionImport
  # Raised, with column names only, when the file doesn't have the columns we need. Better than counting every row as
  # missing data, which would look like a successful run that did nothing.
  class MissingColumns < StandardError; end

  ADDRESS_COLUMNS = %w[address rcpt_to].freeze
  REPLY_COLUMNS = %w[output reply].freeze
  DATE_COLUMNS = %w[date timestamp].freeze

  Result = Struct.new(:suppressed, :already_suppressed, :skipped_failed_before_a_lift,
                      :skipped_refusal_blaming_our_server, :skipped_no_reply, :skipped_no_address, keyword_init: true)

  def self.call(path)
    new.call(path)
  end

  def call(path)
    check_columns!(path)
    result = Result.new(suppressed: 0, already_suppressed: 0, skipped_failed_before_a_lift: 0,
                        skipped_refusal_blaming_our_server: 0, skipped_no_reply: 0, skipped_no_address: 0)
    CSV.foreach(path, headers: true, header_converters: ->(header) { normalise_header(header) }) do |row|
      result[outcome_for(row)] += 1
    end
    result
  end

  private

  def normalise_header(header)
    header.to_s.strip.downcase
  end

  def check_columns!(path)
    headers = (CSV.parse_line(File.open(path, &:gets).to_s) || []).map { |header| normalise_header(header) }
    return if headers.intersect?(ADDRESS_COLUMNS) && headers.intersect?(REPLY_COLUMNS)

    raise MissingColumns, "The file needs a header row with a column named #{ADDRESS_COLUMNS.join(' or ')} " \
                          "and a column named #{REPLY_COLUMNS.join(' or ')}"
  end

  def outcome_for(row)
    address = row["address"] || row["rcpt_to"]
    reply = row["output"] || row["reply"]
    return :skipped_no_address if address.blank?
    return :skipped_no_reply if reply.blank?
    return :skipped_refusal_blaming_our_server if PostalWebhook::BounceRule.blames_sender?(reply)
    return :already_suppressed if EmailSuppression.suppressed?(address)

    failed_at = failed_at(row)
    return :skipped_failed_before_a_lift if recovered_since?(address, failed_at)

    EmailSuppression.suppress!(address, reason: :imported_from_postal, reply: reply, at: failed_at || Time.current)
    :suppressed
  end

  # When the most recent hard fail happened, so a person's notice says since when their emails have been returning.
  # Nil if the file has no usable date.
  def failed_at(row)
    Time.zone.parse(row.values_at(*DATE_COLUMNS).compact.first.to_s)
  rescue ArgumentError
    nil
  end

  # An address someone has since proved works again (a lift) must not be suppressed again by an old export. Without a
  # date we can't tell whether the failure was before or after, so we leave it alone.
  def recovered_since?(address, failed_at)
    lifted_at = EmailSuppression.where(address: address).maximum(:lifted_at)
    lifted_at.present? && (failed_at.nil? || failed_at <= lifted_at)
  end
end
