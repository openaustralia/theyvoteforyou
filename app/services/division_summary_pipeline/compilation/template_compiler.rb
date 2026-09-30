# frozen_string_literal: true

module DivisionSummaryPipeline
  # Stage 5: prints one of the human-curated Markdown templates in templates/, with no AI
  # involvement.
  #
  # This is where the pipeline's guarantee is cashed in. Sentences come from the templates and
  # SummaryWording, numbers from the database (DivisionFacts), what the vote meant from
  # ParliamentaryOutcome, and every quoted or named piece of Hansard from Evidence, which only
  # holds what stage 4 resolved. So nothing here is generated, every part of the output is
  # attributable, and this class decides nothing about parliamentary meaning: it fills in
  # placeholders, degrades to plain text where a value is missing so a reader never sees broken
  # Markdown, and records each such fallback for the reviewer (#fallbacks).
  class TemplateCompiler
    DEFAULT_TEMPLATES_DIR = File.expand_path("../templates", __dir__)

    # Placeholders whose value quotes Hansard or a supplied source word for word. The tidying
    # passes in #render are held off these: they are cosmetic fixes for template prose, and a
    # cosmetic fix applied inside a quotation is a silent edit to the record the summary exists
    # to reproduce (KI-17).
    VERBATIM_PLACEHOLDERS = %w[explanation_section motion_introduction motion_text question_put digest_section
                               regulation_summary urgency_matter_clause limitation_of_debate_section
                               stand_as_printed_parts_sentence].freeze

    # What the last #compile fell back on, for the reviewer report.
    attr_reader :fallbacks

    # division_or_facts: a Division, a Hash of division data, or DivisionFacts.
    # interpretation: ExtractionPayload::Interpretation (template_id, declines_second_reading).
    # evidence: Evidence from stage 4.
    def self.compile(division_or_facts, interpretation, evidence, digest_section: nil, templates_dir: nil)
      new(templates_dir: templates_dir).compile(division_or_facts, interpretation, evidence, digest_section: digest_section)
    end

    def initialize(templates_dir: nil)
      @templates_dir = templates_dir || DEFAULT_TEMPLATES_DIR
      @fallbacks = []
    end

    def compile(division_or_facts, interpretation, evidence, digest_section: nil)
      @fallbacks = []
      facts = division_or_facts.is_a?(DivisionFacts) ? division_or_facts : DivisionFacts.from(division_or_facts)
      outcome = ParliamentaryOutcome.new(facts: facts, template_id: interpretation.template_id,
                                         motion_text: evidence.motion_text, question_text: evidence.question_text,
                                         declines_second_reading: interpretation.declines_second_reading,
                                         circulation: evidence.circulation, limitation_text: evidence.limitation&.text,
                                         closed_template_id: evidence.closed_template_id)
      template = load_template(interpretation.template_id)
      # A template with an "About the Bill" section is a bill template, which is what decides
      # both whether a digest is looked for and whether a missing bill record is worth flagging.
      bill_template = template.include?("{{digest_section}}")
      digest_text = bill_template ? digest(facts, digest_section) : ""
      render(template, placeholders(facts, outcome, evidence, digest_text, bill_template: bill_template))
    end

    # Templates are matched on the leading number alone ("6_third_reading.md" is Template 6);
    # the rest of the file name is for people. Catalogue headings are kept out of the files
    # themselves so they can never leak into published output.
    def load_template(template_id)
      matching = Dir.glob(File.join(@templates_dir, "#{template_id}_*.md"))
      raise Errno::ENOENT, "No template found for ID #{template_id} in #{@templates_dir}" if matching.empty?

      File.read(matching.first, encoding: "utf-8")
    end

    private

    # An unknown placeholder renders as empty rather than being left in place, so a template
    # edited to use a key this class does not build degrades quietly instead of publishing
    # "{{whatever}}". ProvenanceValidator is what stops a required fact going missing here.
    def render(template_text, data)
      verbatim = {}
      rendered = template_text.gsub(/\{\{([^}]+)\}\}/) do
        key = Regexp.last_match(1).strip
        value = data[key].to_s
        # An empty value has nothing to protect, and held back it would survive the blank-line
        # tidying below as a gap in the page.
        next value unless VERBATIM_PLACEHOLDERS.include?(key) && value.present?

        token = "\u0000VERBATIM#{verbatim.size}\u0000"
        verbatim[token] = value
        token
      end

      # An unresolved link degrades to plain text ("[Name]()" -> "Name"), and an empty pair of
      # brackets left by a missing party disappears.
      rendered.gsub!(/\[([^\]]+)\]\(\s*\)/, "\\1")
      rendered.gsub!(/\s*\(\s*\)/, "")
      rendered.gsub!(/[ \t]{2,}/, " ")
      # A template that writes "the" before a value that already carries one ("to the
      # {{committee_name}}" where Hansard names "the Economics Committee").
      rendered.gsub!(/\b([Tt]he)\s+the\s+/, "\\1 ")
      rendered.gsub!(/[ \t]+$/, "")
      rendered.gsub!(/\n{3,}/, "\n\n")

      # Block form, so a backslash in quoted Hansard is never read as a replacement reference.
      verbatim.each { |token, value| rendered.sub!(token) { value } }
      rendered.strip
    end

    # One table for every template, each of which uses only the keys it needs.
    def placeholders(facts, outcome, evidence, digest_text, bill_template:)
      wording = SummaryWording.new(outcome)
      entry = TemplateCatalogue.fetch(outcome.template_id)
      mover = mover_details(facts, evidence)
      sections = EvidenceSections.new(evidence, facts, mover_label: mover[:label], moved: entry.moved)
      note_evidence_fallbacks(evidence, entry)
      note_outcome_fallbacks(outcome, bill_template: bill_template)
      bill = bill_reference(facts)
      target = resolve_target(facts, evidence, outcome.template_id)

      {
        "time" => facts.time,
        "amount" => wording.amount,
        "amount_with_article" => wording.amount_with_article,
        "result" => wording.result_phrasing,
        "successful_text" => wording.successful_text,
        "mover_title" => mover[:title],
        "mover_name" => mover[:name],
        "mover_link" => mover[:link],
        "mover_party" => mover[:party],
        "mover_clause" => mover[:clause],
        "proposer_clause" => proposer_clause(facts, evidence),
        "bill_name" => facts.bill_name.presence || "bill",
        "bill_link" => facts.bill_link,
        "chamber" => facts.chamber,
        "other_chamber" => facts.other_chamber,
        "rebellions_text" => wording.rebellions_text,
        "digest_section" => digest_text,
        "intro_sentence" => outcome.template_id == 2 ? wording.second_reading_amendment_sentence(mover[:clause], bill) : "",
        "amendment_phrase" => wording.amendment_phrase,
        "means_clause" => wording.means_clause,
        "explanation_section" => sections.explanation,
        "motion_introduction" => sections.introduction,
        "motion_attribution" => sections.motion_attribution,
        "motion_text" => sections.motion,
        "question_put" => sections.question,
        "limitation_of_debate_section" => limitation_of_debate_section(sections, wording),
        "amendment_effect_clause" => wording.amendment_effect_clause,
        "carried_amendment_note" => wording.carried_amendment_note,
        "stand_as_printed_effect_clause" => wording.stand_as_printed_effect_clause,
        "stand_as_printed_parts_sentence" => wording.stand_as_printed_parts_sentence,
        "second_reading_clause" => wording.second_reading_clause,
        "passing_stage_clause" => wording.passing_stage_clause,
        "third_reading_clause" => wording.third_reading_clause,
        "continuation_clause" => wording.continuation_clause,
        "suspension_effect_clause" => wording.suspension_effect_clause,
        "suspension_purpose_clause" => wording.suspension_purpose_clause,
        "urgency_matter_clause" => wording.urgency_matter_clause,
        "suspension_form" => wording.suspension_form,
        "suspension_period_sentence" => wording.suspension_period_sentence,
        "message_action_clause" => wording.message_action_clause,
        "message_effect_clause" => wording.message_effect_clause,
        "general_motion_effect_clause" => wording.general_motion_effect_clause,
        "closure_explainer" => wording.closure_explainer,
        "closure_action_clause" => wording.closure_action_clause(facts.bill_name.present? ? bill : nil),
        "followup_clause" => wording.followup_clause,
        "adjournment_effect_clause" => wording.adjournment_effect_clause,
        "regulation_status_clause" => wording.regulation_status_clause,
        "target_name" => target_name(target, evidence),
        "target_clause" => target_clause(target, evidence),
        "committee_name" => evidence.fact(:committee_name).to_s,
        "business_name" => evidence.fact(:business_name).to_s,
        "regulation_name" => evidence.fact(:regulation_name).to_s,
        "regulation_link" => facts[:regulation_link].to_s,
        "regulation_summary" => facts[:regulation_summary].to_s,
        "rearrangement_description" => wording.rearrangement_clause(evidence.fact(:rearrangement_description)),
        "motion_link" => facts[:motion_link].to_s,
        "on_bill_clause" => facts.bill_name.present? ? " on the #{bill}" : ""
      }
    end

    # The bill as a link, or the bare word "bill" when the division has none, which reads only
    # after "the" ("to the bill"): anywhere else pass nil instead (see closure_action_clause).
    def bill_reference(facts)
      facts.bill_name.present? ? "[#{facts.bill_name}](#{facts.bill_link})" : "bill"
    end

    # Empty unless Stage 1 found the chair saying a limitation of debate's time had expired, or
    # that the question was put immediately under a resolution agreed earlier.
    def limitation_of_debate_section(sections, wording)
      statement = sections.limitation
      return "" unless statement

      [wording.limitation_lead, statement, wording.limitation_effect].compact.join("\n\n")
    end

    # A Bills Digest section, when one is supplied (ARCHITECTURE.md section 15): pre-formatted,
    # or built from its link and key points. Otherwise the fallback the original template design
    # document prescribes (TEMPLATES.md, which is not in this repository).
    def digest(facts, digest_section)
      supplied = digest_section.presence || facts[:digest_section].presence
      return supplied if supplied

      points = facts[:digest_key_points]
      if points.is_a?(Array) && points.any?
        link = facts[:digest_link].to_s
        header = link.present? ? "According to the [Bill Digest](#{link}):" : "According to the Bill Digest:"
        return "#{header}\n\n#{points.map { |point| "> * #{point}" }.join("\n")}"
      end

      @fallbacks << :no_digest
      "> No Bill Digest found."
    end

    # The mover as the summary names them: the caller's own details when it supplies them (the
    # evaluation fixtures do), otherwise the member Stage 1 found by rule, otherwise nobody.
    # `clause` is what lets a template leave the mover out altogether rather than naming "a
    # member": at the scheduled time the Speaker proposes the adjournment with nobody moving it
    # (House S.O. 31), and under a limitation of debate the chair puts circulated amendments and
    # the remaining stages with nobody moving them, when the clause says who circulated them
    # instead, if Hansard says.
    def mover_details(facts, evidence)
      details = supplied_mover(facts) || found_mover(facts, evidence.mover)
      return circulated_details(facts, evidence.circulation) if details.nil? && evidence.circulation

      unless details
        @fallbacks << :mover_unresolved
        return { name: "", link: "", party: "", title: "", suffix: "", clause: "", label: nil }
      end

      details.merge(clause: " introduced by #{member_phrase(details)}",
                    label: "#{details[:title]} #{details[:name]}#{details[:suffix]}".strip)
    end

    # "Senator [Name](link) (Party)" or "[Name](link) MP (Party)": the site's own forms
    # (Member#full_name_no_electorate), with the link round the name alone.
    def member_phrase(details)
      title = "#{details[:title]} " if details[:title].present?
      "#{title}[#{details[:name]}](#{details[:link]})#{details[:suffix]} (#{details[:party]})"
    end

    # " on behalf of Senator [Name](link) (Party)", for a matter of urgency moved by someone other
    # than its proposer, when a mover is named at all.
    def proposer_clause(facts, evidence)
      return "" unless evidence.proposer && evidence.mover

      details = found_mover(facts, evidence.proposer)
      details ? " on behalf of #{member_phrase(details)}" : ""
    end

    # "circulated by the Australian Greens", or by a member the database knows, linked like a mover.
    def circulated_details(facts, circulation)
      member = found_mover(facts, circulation.member)
      by = member ? member_phrase(member) : circulation.by
      { name: "", link: "", party: "", title: "", suffix: "", clause: by ? " circulated by #{by}" : "", label: nil }
    end

    # A caller that supplies a title (the evaluation fixtures do) gets it in front of the name.
    def supplied_mover(facts)
      name = facts[:mover_name].presence
      return nil unless name

      supplied = facts[:mover_title].presence || facts[:title].presence
      naming = supplied ? { title: supplied, suffix: "" } : chamber_naming(facts.senate?)
      party = (facts[:mover_party].presence || facts[:party]).to_s
      { name: name, link: facts[:mover_link].to_s, party: party }.merge(naming)
    end

    # "Senator Example" or "Example MP", never "Representative Example", which is not Australian
    # usage (KI-24).
    def found_mover(facts, mover)
      return nil if mover&.name.blank?

      senator = mover.member ? mover.member.senator? : facts.senate?
      { name: mover.name, link: mover.link.to_s, party: mover.party.to_s }.merge(chamber_naming(senator))
    end

    def chamber_naming(senator)
      senator ? { title: "Senator", suffix: "" } : { title: "", suffix: " MP" }
    end

    # Asks the database for the member the motion targets, so party, electorate and the profile
    # link come from TVFY records rather than anything the model could invent. What Hansard
    # names but the database cannot match degrades to plain text.
    def resolve_target(facts, evidence, template_id)
      return nil unless [10, 23, 24].include?(template_id)

      MemberResolver.resolve(name: evidence.fact(:target_name).presence || facts[:target_name].presence,
                             electorate: evidence.fact(:target_electorate).presence,
                             house: facts.house_key, date: facts.date.presence)
    end

    def target_name(target, evidence)
      return target.name if target&.name.present?

      evidence.fact(:target_name).presence || "the member"
    end

    # Template 23 and 24's target phrase: "Dickson MP [Name](link) (Party)" for a database
    # match, and otherwise the member named the way Hansard names them.
    def target_clause(target, evidence)
      return linked_target(target) if target&.member

      electorate = evidence.fact(:target_electorate)
      return "the honourable member for #{electorate}" if electorate.present?

      evidence.fact(:target_name).presence || "the member"
    end

    def linked_target(target)
      descriptor = if target.member.senator? then "Senator"
                   elsif target.electorate.present? then "#{target.electorate} MP"
                   else "MP"
                   end
      party = target.party.present? ? " (#{target.party})" : ""
      "#{descriptor} [#{target.name}](#{target.link})#{party}"
    end

    def note_evidence_fallbacks(evidence, entry)
      @fallbacks << :no_explanation if entry.explains && evidence.explanations.empty?
      @fallbacks << :no_introduction unless evidence.introduction
      @fallbacks << :no_motion_terms unless evidence.motion
      @fallbacks << :no_question unless evidence.question
    end

    def note_outcome_fallbacks(outcome, bill_template:)
      @fallbacks << :no_bill_record if bill_template && outcome.facts.bill_name.blank?
      @fallbacks << :tied if outcome.tied?
      @fallbacks << :want_of_quorum if outcome.want_of_quorum?
      @fallbacks << :absolute_majority_in_doubt if outcome.absolute_majority_in_doubt?
    end
  end
end
