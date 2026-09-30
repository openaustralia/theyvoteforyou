# frozen_string_literal: true

module DivisionSummaryPipeline
  # A draft's title, built by rule from the Hansard heading and the template, so the model has
  # no say in it:
  #
  #   <major heading> - <minor heading without its last "; ..." part>; <template's procedure>
  #   "Bills - Universities Accord (Opening the Doors of Opportunity) Bill 2026; Second Reading Amendment"
  #
  # The last part of a minor heading names the stage the debate was at ("; Second Reading"),
  # which the template names more exactly for this division ("Second Reading Amendment"), so it
  # is replaced rather than repeated. Some titles repeat themselves as a result ("Matters of
  # Urgency - Migration; Matter of Urgency"); that was accepted in exchange for every title
  # saying what the vote was (decided September 2026).
  module DraftTitle
    # DataLoader::DivisionXml#name joins the major and minor headings with this, and writes any
    # em dash inside a heading the same way.
    HEADING_JOIN = /\s*(?:&#8212;|\u2014)\s*/

    module_function

    # bill_titles: the division's bills as the bills table records them. The heading comes
    # title-cased (DataLoader::DivisionXml#name, which has to stay PHP-compatible), which turns
    # "NDIS" into "Ndis", so a bill's title found in it, ignoring case, is printed as the bill
    # records it (KI-48).
    def for(heading:, template_id: nil, fallback: nil, bill_titles: [])
      major, minor = TextNormaliser.clean_text(heading).split(HEADING_JOIN, 2)
      subject = minor.to_s.split(";").map(&:strip)
      subject = subject[0...-1] if subject.size > 1
      title = [major, subject.join("; ").presence].compact_blank.join(" - ").gsub(HEADING_JOIN, " - ")
      title = TextNormaliser.clean_text(fallback).gsub(HEADING_JOIN, " - ") if title.blank?
      Array(bill_titles).compact_blank.each { |bill| title = title.gsub(/#{Regexp.escape(bill)}/i) { bill } }

      procedure = TemplateCatalogue[template_id]&.title
      procedure ? [title.presence, procedure].compact.join("; ") : title
    end
  end
end
