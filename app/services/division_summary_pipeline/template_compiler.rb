# frozen_string_literal: true

module DivisionSummaryPipeline
  # Stage 5: merges authoritative TVFY facts and validated extractions into one of the 28
  # human-curated Markdown templates in templates/, with no AI involvement.
  #
  # This is where the pipeline's guarantee is cashed in. Published sentences come from the
  # templates, numbers from the database, quoted passages from Hansard by way of stage 4, so
  # nothing here is generated and every part of the output is attributable. The awkward
  # details below are therefore grammar and degradation, not judgement: articles, duplicated
  # determiners, and falling back to plain text so an unresolved value cannot render as
  # broken Markdown in front of a reader.
  #
  # Some clauses here are chosen from the extracted motion text rather than written into a
  # template, because one template covers several questions that mean different things: the
  # message family (agree, disagree, insist, does not insist, request) and the three closures.
  # They are still deterministic, human-authored strings; the branch is what the model's
  # verbatim extraction selects, not what it writes.
  class TemplateCompiler
    DEFAULT_TEMPLATES_DIR = File.expand_path("templates", __dir__)

    # The House grew from 150 to 151 seats at the 2019 election, which moved the quorum
    # (one fifth of the House) from 30 to 31. See #house_quorum_threshold.
    HOUSE_OF_151_FROM = Date.new(2019, 7, 1)

    def self.compile(division_or_data, extraction, digest_section: nil, templates_dir: nil)
      new(templates_dir: templates_dir).compile(division_or_data, extraction, digest_section: digest_section)
    end

    def initialize(templates_dir: nil)
      @templates_dir = templates_dir || DEFAULT_TEMPLATES_DIR
    end

    # Placeholders whose value is source text reproduced word for word: the motion as Hansard
    # records it, the mover's claims once stage 4 has cleared them, a supplied Bills Digest or
    # Explanatory Statement extract. The tidying passes in #compile are held off these. They
    # are cosmetic fixes for template prose, and a cosmetic fix applied inside a quotation is
    # a silent edit to the record the summary exists to reproduce: collapsing a run of spaces
    # in a quoted motion, or "correcting" an article inside something a member actually said.
    VERBATIM_PLACEHOLDERS = %w[motion_text introducer_claims digest_section regulation_summary].freeze

    # An unknown placeholder renders as empty rather than being left in place, so a template
    # edited to use a key this class does not build degrades quietly instead of publishing
    # "{{whatever}}". ProvenanceValidator is what stops a required fact going missing here.
    def compile(division_or_data, extraction, digest_section: nil)
      template_text = load_template(extraction.template_id)
      data = prepare_compilation_data(division_or_data, extraction, digest_section)

      verbatim = {}
      rendered = template_text.gsub(/\{\{([^}]+)\}\}/) do
        key = Regexp.last_match(1).strip
        value = data[key].nil? ? "" : data[key].to_s
        next value unless VERBATIM_PLACEHOLDERS.include?(key)

        token = "\u0000VERBATIM#{verbatim.size}\u0000"
        verbatim[token] = value
        token
      end

      # Clean up empty markdown links like [Name]() -> Name, and empty parentheses like () -> ""
      rendered.gsub!(/\[([^\]]+)\]\(\s*\)/, "\\1")
      rendered.gsub!(/\s*\(\s*\)/, "")

      # Collapse multiple horizontal whitespace within lines
      rendered.gsub!(/[ \t]{2,}/, " ")

      # Collapse a duplicated definite article, which comes from a template that writes "the"
      # before a value that already carries one ("to the {{committee_name}}" where the
      # committee name Hansard states is "the Economics Committee"). The indefinite article is
      # no longer patched up here: {{amount_with_article}} carries its own, so "a" and "an" are
      # chosen once, from the value, rather than repaired afterwards across the whole document.
      rendered.gsub!(/\b([Tt]he)\s+the\s+/, "\\1 ")

      # Clean up excess consecutive newlines
      rendered.gsub!(/\n{3,}/, "\n\n")

      # Block form, so a backslash in quoted Hansard is never read as a replacement reference.
      verbatim.each { |token, value| rendered.sub!(token) { value } }

      rendered.strip
    end

    # Templates are matched on the leading number alone ("6_passing_a_bill.md" is Template
    # 6); the rest of the file name is for people. Catalogue headings are kept out of the
    # files themselves so they can never leak into published output (ARCHITECTURE.md § 8).
    def load_template(template_id)
      pattern = File.join(@templates_dir, "#{template_id}_*.md")
      matching = Dir.glob(pattern)
      raise Errno::ENOENT, "No template found for ID #{template_id} in #{@templates_dir}" if matching.empty?

      File.read(matching.first, encoding: "utf-8")
    end

    def prepare_compilation_data(division_or_data, extraction, digest_section)
      raw = extract_attributes(division_or_data)
      template_id = extraction.template_id

      # 1. Chamber logic
      house = raw[:house].to_s.downcase
      is_senate = house.include?("senate")
      chamber = is_senate ? "Senate" : "House of Representatives"
      other_chamber = is_senate ? "House of Representatives" : "Senate"

      # 2. Result and success phrasing. One list decides both: every template's intro sentence
      # reads "voted for/against ...", so any raw result spelling is normalised to those two
      # words here rather than interpolated as-is.
      result_raw = raw[:result].to_s.downcase
      is_successful = ["passed", "agreed to", "for", "yes", "successful", "carried"].include?(result_raw)

      successful_text = is_successful ? "successful" : "unsuccessful"
      result_phrasing = is_successful ? "for" : "against"
      amendment_effect_clause = is_successful ? "The text of the bill has been changed accordingly." : ""

      # Template 28 ("That the [unit] stand as printed") is the one question whose result and
      # whose effect on the bill point opposite ways: carrying it keeps the unit, defeating it
      # omits the unit (Guides to Senate Procedure, No. 16). The vote direction reported above
      # stays true to the question actually put, because that is what the aye and no counts on
      # the page are counts of. The consequence is spelled out separately so the two cannot be
      # read as contradicting each other.
      stand_as_printed_effect_clause =
        if template_id != 28
          ""
        elsif is_successful
          "Because the question was that it stand as printed, agreeing to it kept that part of the bill unchanged and defeated the amendment to omit it."
        else
          "Because the question was that it stand as printed, defeating the question is what omitted that part of the bill. The amendment to omit it therefore succeeded, and the text of the bill has changed accordingly."
        end

      # 3. Quorum and tied vote logic
      aye_votes = raw[:aye_votes].to_i
      no_votes = raw[:no_votes].to_i
      turnout = raw[:turnout].to_i
      turnout = aye_votes + no_votes if turnout.zero? && (aye_votes + no_votes).positive?

      member_count = chamber_member_count(raw)
      quorum_threshold = house_quorum_threshold(raw[:date], member_count)
      is_want_of_quorum = !is_senate && quorum_threshold && turnout.positive? && turnout < quorum_threshold
      is_tied = raw[:tied] || (turnout.positive? && aye_votes == no_votes && !is_want_of_quorum)

      # An equally divided division had no majority either way, so "voted for" and "voted
      # against" are both wrong about it. The two chambers then resolve it differently: the
      # Senate loses the question (Constitution s 23), while in the House the occupant of the
      # Chair has a casting vote (s 40) that the aye and no counts do not record. So the House
      # result is reported as undetermined rather than asserted from figures that cannot
      # settle it, and the notice below says why.
      result_phrasing = "on" if is_tied
      successful_text = "not decided by the division figures, which were equal" if is_tied && !is_senate

      successful_text = "not decided, because fewer than a quorum of members voted" if is_want_of_quorum

      # 4. Majority amount formatting. The article is computed rather than written into the
      # templates because the wording varies ("a majority", "an overwhelming majority").
      raw_amount = raw[:amount].presence
      if is_tied && (raw_amount.blank? || raw_amount == "majority")
        raw_amount = "equally divided #{chamber}"
      elsif raw_amount.blank?
        raw_amount = "majority"
      end
      clean_amount = raw_amount.sub(/\A[Aa]n?\s+/, "").strip
      amount_with_article = clean_amount.downcase =~ /\A[aeiou]/ ? "an #{clean_amount}" : "a #{clean_amount}"

      # 5. Basic attributes. Mover details are resolved via MemberResolver from Hansard speaker claims
      # or raw division data, never falling back to debate headings. Unresolved details degrade cleanly.
      time = raw[:time].presence || raw[:clock_time].to_s
      mover_attrs = resolve_mover_attributes(raw, extraction, is_senate)
      mover_name = mover_attrs[:name]
      mover_link = mover_attrs[:link]
      mover_party = mover_attrs[:party]
      mover_title = mover_attrs[:title]

      bill_name = raw[:bill_name].presence || extraction.topic
      bill_link = raw[:bill_link].to_s

      # Needed before the notices in step 6 as well as by the stage clause in step 10, so both
      # read the same answer rather than working it out twice.
      stage_val = raw[:stage].presence || stage_from_motion(extraction)
      is_constitution_bill = [bill_name, extraction.topic].compact.any? { |t| t.to_s.match?(/constitution\s+alteration/i) }

      # 6. Rebellions text (members voting against their own party) and procedural notices.
      is_free_vote = raw[:free_vote] || (division_or_data.respond_to?(:whips) && division_or_data.whips.any?(&:free?))

      rebellions_text = if is_free_vote
                          "This was a conscience vote (free vote). Members were not bound by party whips, so no party rebellions are recorded.\n"
                        else
                          rebellions_val = raw[:rebellions]
                          if rebellions_val.is_a?(String) && rebellions_val.strip.present?
                            "#{rebellions_val.strip}\n"
                          elsif rebellions_val.is_a?(Integer) && rebellions_val.positive?
                            "#{rebellions_val} member(s) voted against their party.\n"
                          else
                            "Nobody voted against their party on this occasion.\n"
                          end
                        end

      if is_want_of_quorum
        rebellions_text += "Notice: only #{turnout} members voted, fewer than the quorum of #{quorum_threshold}. Under House Standing Order 58 the House does not make a decision on a question when a division shows fewer than a quorum voting.\n"
      elsif is_tied
        # The two chambers resolve an equally divided vote in opposite ways, so this is one of
        # the few places a summary has to know which chamber it is in. The Senate wording
        # follows the Guides to Senate Procedure ("the question is lost") rather than section
        # 23's own "shall pass in the negative", which a reader can easily take to mean it passed.
        rebellions_text += if is_senate
                             "Because the votes were equally divided, the question was lost. The President of the Senate votes as an ordinary senator and has no casting vote, so under Section 23 of the Constitution an equally divided question fails.\n"
                           else
                             "Because the votes were equally divided, the result was decided by the casting vote of the occupant of the Chair. Under Section 40 of the Constitution the Speaker does not vote unless the numbers are equal, and then has a casting vote. The division figures do not record which way that casting vote went, so this one needs checking against the official record.\n"
                           end
      end

      # Questions that need an absolute majority, a majority of all the members of the chamber
      # rather than of those voting. Where the ayes clear a simple majority but fall short of
      # the absolute one, the recorded result and the requirement disagree, and the pipeline
      # says so rather than picking a side (KNOWN_ISSUES.md, KI-5).
      absolute_majority = absolute_majority_threshold(member_count, is_senate)
      absolute_majority_notice = absolute_majority_notice(
        requirement: absolute_majority_requirement(
          template_id: template_id,
          motion_text: extraction.motion_text,
          is_senate: is_senate,
          is_constitution_bill: is_constitution_bill,
          stage: stage_val
        ),
        aye_votes: aye_votes,
        threshold: absolute_majority,
        chamber: chamber,
        is_successful: is_successful
      )
      rebellions_text += absolute_majority_notice if absolute_majority_notice.present?

      # 7. Digest section.
      final_digest = digest_section || raw[:digest_section]
      if final_digest.blank?
        if raw[:digest_key_points].is_a?(Array) && raw[:digest_key_points].any?
          pts = raw[:digest_key_points].map { |p| "> * #{p}" }.join("\n")
          link = raw[:digest_link].to_s
          header = link.present? ? "According to the [Bill Digest](#{link}):" : "According to the Bill Digest:"
          final_digest = "#{header}\n\n#{pts}"
        else
          final_digest = "> No Bill Digest found."
        end
      end

      # 8. Formatted motion and claims blockquotes
      formatted_motion = format_blockquote(extraction.motion_text)
      formatted_claims = format_claims_blockquote(extraction)

      # 9. Template 2 intro sentence
      intro_sentence = ""
      if template_id == 2
        base_sentence = "At #{time}, #{amount_with_article} voted #{result_phrasing} a second reading amendment " \
                        "introduced by #{mover_title} [#{mover_name}](#{mover_link}) (#{mover_party}) to the " \
                        "[#{bill_name}](#{bill_link}), which means it was #{successful_text}."
        intro_sentence = if extraction.declines_second_reading
                           "#{base_sentence} Because the amendment sought to decline the bill a second reading, " \
                             "a vote for it was in effect a vote against the bill proceeding."
                         else
                           "#{base_sentence} The text of the bill is unchanged either way."
                         end
      end

      # 10. Bill stages and Constitution Alteration bills (stage_val and is_constitution_bill
      # were worked out in step 5, because the notices in step 6 need them too).
      stage_clause = bill_stage_clause(
        stage: stage_val,
        is_successful: is_successful,
        is_constitution_bill: is_constitution_bill,
        is_senate: is_senate,
        chamber: chamber,
        other_chamber: other_chamber,
        originating_house: raw[:bill_originating_house],
        # nil means "no figures to judge it by", which is not the same as "not met".
        absolute_majority_met: (aye_votes >= absolute_majority if absolute_majority && aye_votes.positive?)
      )

      # 11. Target resolution for the templates that name a second person (10, 23, 24).
      target = resolve_target(raw, extraction)

      msg_form = message_form(extraction.motion_text)

      # One table for all 28 templates, each of which uses only the keys it needs.
      {
        "time" => time,
        "amount" => clean_amount,
        "amount_with_article" => amount_with_article,
        "result" => result_phrasing,
        "successful_text" => successful_text,
        "mover_title" => mover_title,
        "mover_name" => mover_name,
        "mover_link" => mover_link,
        "mover_party" => mover_party,
        "bill_name" => bill_name,
        "bill_link" => bill_link,
        "topic" => extraction.topic,
        "intro_sentence" => intro_sentence,
        "rebellions_text" => rebellions_text,
        "digest_section" => final_digest,
        "introducer_claims" => formatted_claims,
        "motion_text" => formatted_motion,
        "chamber" => chamber,
        "other_chamber" => other_chamber,
        "amendment_effect_clause" => amendment_effect_clause,
        "stand_as_printed_effect_clause" => stand_as_printed_effect_clause,
        # A gag motion is put on whoever is speaking, which is often not about a bill at all,
        # so the debate is named rather than linked: bill_name falls back to the topic and
        # would otherwise render a link to the closure as though it were a bill.
        "continuation_clause" => is_successful ? "They were unable to continue speaking, and the debate went on without them." : "They were able to continue speaking.",
        "suspension_effect_clause" => is_successful ? "The usual rules were set aside so the matter could be dealt with immediately." : "",
        "suspension_purpose_clause" => suspension_purpose_clause(extraction, template_id),
        "suspension_form" => is_senate ? "sitting" : "service",
        "suspension_period_sentence" => suspension_period_sentence(is_senate),
        "message_action_clause" => message_action_clause(msg_form, chamber, other_chamber),
        "message_effect_clause" => message_effect_clause(
          form: msg_form, is_successful: is_successful, is_tied: is_tied,
          is_senate: is_senate, chamber: chamber, other_chamber: other_chamber
        ),
        "general_motion_effect_clause" => general_motion_effect_clause(extraction, template_id, chamber),
        "closure_explainer" => closure_explainer(extraction.motion_text),
        "closure_action_clause" => closure_action_clause(extraction.motion_text, bill_name, bill_link),
        "mover_clause" => mover_attrs[:resolved] ? " introduced by #{mover_title} [#{mover_name}](#{mover_link}) (#{mover_party})" : "",
        "adjournment_effect_clause" => adjournment_effect_clause(template_id, is_successful, is_tied, chamber),
        "stage" => stage_val,
        "stage_clause" => stage_clause,
        "target_name" => target_name_value(target, extraction, raw),
        "target_clause" => target_clause(target, extraction),
        "committee_name" => extraction.committee_name.presence || raw[:committee_name] || "",
        "business_name" => extraction.business_name.presence || raw[:business_name] || "",
        "motion_link" => raw[:motion_link] || "",
        "rearrangement_description" => extraction.rearrangement_description.presence || raw[:rearrangement_description] || "",
        "regulation_name" => extraction.regulation_name.presence || raw[:regulation_name] || "",
        "regulation_link" => raw[:regulation_link] || "",
        "regulation_summary" => raw[:regulation_summary] || "",
        "regulation_status_clause" => is_successful ? "The regulation no longer has legal force." : "The regulation remains in force.",
        # TEMPLATES.md's closure template points the reader at the division that put the underlying
        # question ("the [Chamber] then voted on the question itself, which you can read about here
        # (LINK to the following division)"). The follow-up division link is only rendered when a
        # followup_link attribute is supplied; resolving that link is not built yet.
        "followup_clause" => followup_clause(chamber, is_successful, raw[:followup_link], motion_text: extraction.motion_text)
      }
    end

    # Three different questions arrive as Template 22 and only the operative motion text tells
    # them apart, so the explainer, the description of what was moved and the trailing clause
    # are all chosen from it rather than from the debate heading (the same rule the router
    # follows, ARCHITECTURE.md constraint 3):
    #
    # - the ordinary closure, "That the question be now put", after which the question it cut
    #   short is put immediately (House S.O. 81);
    # - "That the business of the day be called on", which exists only to curtail a discussion
    #   on a matter of public importance and is provided precisely "because there is no
    #   question before the Chair during an MPI" (House Guide pp. 40-41, S.O. 46(e)), so no
    #   second division follows it;
    # - "That the ballot be taken now", the closure used during the election of a Speaker
    #   (House S.O. 11(h), Guide p. 41).
    #
    # Describing the last two as a closure that forces an immediate vote on the matter under
    # discussion contradicted the trailing clause in the same paragraph (KNOWN_ISSUES.md, KI-3).
    def closure_variant(motion_text)
      text = motion_text.to_s
      return :business_of_the_day if text.match?(/business of the day be called on/i)
      return :ballot if text.match?(/ballot be taken now/i)

      :closure
    end

    def closure_explainer(motion_text)
      case closure_variant(motion_text)
      when :business_of_the_day
        "*This motion ends a discussion on a matter of public importance. Such a discussion has no " \
        "question before the Chair, so there is nothing for the chamber to decide at the end of it, " \
        "and this motion is the only way to cut one short. If it is agreed to the discussion stops " \
        "and the chamber moves on to the next item of business.*"
      when :ballot
        "*During the election of a Speaker this is the motion used to end the debate so the ballot can " \
        "be held. It decides only that the ballot happens now.*"
      else
        "*This motion stops the debate and forces an immediate vote on whatever is being discussed. It " \
        "decides only that the talking ends. It does not decide the underlying question, which is put " \
        "to a separate vote straight afterwards. It cannot be moved for proceedings already covered by " \
        "a time limit (a 'guillotine'), because the timetable has taken its place.*"
      end
    end

    def closure_action_clause(motion_text, bill_name, bill_link)
      case closure_variant(motion_text)
      when :business_of_the_day
        "to call on the business of the day and end the discussion"
      when :ballot
        "to end the debate and take the ballot immediately"
      else
        "to end the debate on [#{bill_name}](#{bill_link}) and put the question immediately"
      end
    end

    def followup_clause(chamber, is_successful, followup_link, motion_text: nil)
      variant = closure_variant(motion_text)

      unless is_successful
        return "The discussion continued." if variant == :business_of_the_day
        return "Debate on the election continued." if variant == :ballot

        return "The debate continued."
      end

      case variant
      when :business_of_the_day
        "There was no question before the Chair to decide, so the #{chamber} moved straight to the next item of business."
      when :ballot
        "The #{chamber} then proceeded to the ballot."
      else
        if followup_link.present?
          "The #{chamber} then voted on the question itself, which you can read about [here](#{followup_link})."
        else
          "The #{chamber} then voted on the question itself."
        end
      end
    end

    # A suspension motion states its own purpose, in the words after "as would prevent" (House
    # Guide p. 2). Suspensions are moved for many different reasons - to move a motion without
    # notice, to make a statement or table a document after leave was refused, to rearrange
    # business, to bring on a disallowance, a censure or a guillotine - so a stock "to debate an
    # urgent matter" was a guess, and read as a characterisation of the matter rather than a
    # description of the vote (KNOWN_ISSUES.md, KI-10). Falls back to naming the topic, and to
    # saying nothing at all when even that is missing.
    def suspension_purpose_clause(extraction, template_id)
      return "" unless template_id == 17

      match = extraction.motion_text.to_s.match(/as would prevent\s+(.{3,240}?)(?:[.;:]|\z)/im)
      if match
        purpose = match[1].to_s.gsub(/\s+/, " ").strip.sub(/[,-]\z/, "")
        return " to set aside the rules that would otherwise prevent #{purpose}" if purpose.present?
      end

      extraction.topic.presence ? " regarding #{extraction.topic}" : ""
    end

    # House S.O. 94(d) sets escalating periods rather than "the remainder of the sitting", and
    # the Senate uses a different form of words again (KNOWN_ISSUES.md, KI-7). Senate S.O. 204
    # covers the Senate's periods but the Guides to Senate procedure do not state what they
    # are, so this says where to look instead of asserting them.
    def suspension_period_sentence(is_senate)
      if is_senate
        "The Senate names a senator under standing order 203 and sets the period of suspension under " \
          "standing order 204; the Senate's own guide does not state those periods, so they are not given here."
      else
        "A member suspended from the service of the House is excluded from the Chamber, all its galleries " \
          "and any room where the Federation Chamber is meeting, and while suspended cannot present " \
          "petitions, give notices or propose a matter of public importance, though they may still serve " \
          "on a committee. The suspension runs for 24 hours on a first occasion, three consecutive sittings " \
          "on a second occasion in the same calendar year, and seven consecutive sittings on a third or " \
          "later occasion, in each case not counting the day of the suspension."
      end
    end

    # Template 7 covers the whole message family, and the forms in it do not all mean the same
    # thing, or even point the same way. "That the committee does not insist on its amendments"
    # is carried to drop them and defeated to keep them, and the amendments in question are this
    # chamber's own rather than the other chamber's (Senate Guide No. 18). Reporting every form
    # as "to agree to the other chamber's amendments" was wrong twice over in that case
    # (KNOWN_ISSUES.md, KI-2), so the form is read off the motion text the extractor returned.
    #
    # Order matters: "does not insist on its amendments to which the House has disagreed"
    # contains "disagreed", and "disagreed" contains "agree".
    def message_form(motion_text)
      text = motion_text.to_s.downcase
      return :not_insist if text.match?(/\b(?:does not|do not|not)\s+insist\b/)
      return :insist if text.match?(/\binsist/)
      return :request if text.match?(/\brequest/)
      return :disagree if text.match?(/\bdisagree/)
      return :agree if text.match?(/\bagree/)

      :unknown
    end

    def message_action_clause(form, chamber, other_chamber)
      case form
      when :agree then "to agree to the amendments the #{other_chamber} made"
      when :disagree then "to disagree to the amendments the #{other_chamber} made"
      when :not_insist then "that the #{chamber} not insist on its own amendments"
      when :insist then "that the #{chamber} insist on its own amendments"
      when :request then "about the Senate's requests for amendments"
      else "concerning the amendments made"
      end
    end

    SECTION_53_NOTE = "Section 53 of the Constitution stops the Senate amending a bill imposing taxation or " \
                      "appropriating money for the ordinary annual services of the government, so the Senate " \
                      "asks the House of Representatives to make the change instead. The House may make the " \
                      "requested amendment, decline to make it, or make it in a modified form."

    def message_effect_clause(form:, is_successful:, is_tied:, is_senate:, chamber:, other_chamber:)
      return SECTION_53_NOTE if form == :request
      return not_insist_effect_clause(is_successful, is_tied, is_senate, chamber, other_chamber) if form == :not_insist

      case form
      when :agree
        if is_successful
          "Agreeing to the motion accepted the #{other_chamber}'s changes to the bill."
        else
          "Defeating the motion means the #{other_chamber}'s changes were not accepted, so the bill goes back to it for further negotiation."
        end
      when :disagree
        if is_successful
          "Agreeing to the motion rejected the #{other_chamber}'s changes, and the bill goes back to it with the reasons for the disagreement."
        else
          "Defeating the motion means the #{other_chamber}'s changes were not rejected at this point."
        end
      when :insist
        if is_successful
          "Agreeing to the motion means the #{chamber} kept its own amendments, so the bill goes back to the #{other_chamber} with them."
        else
          "Defeating the motion means the #{chamber} did not insist on its own amendments, so the bill proceeds without them."
        end
      else
        ""
      end
    end

    # The inverted one. Senate Guide No. 18: "if a majority votes against the motion, the effect
    # is that the amendments are insisted on", while an equally divided vote goes the other way,
    # because the tie shows the amendments no longer command a majority.
    def not_insist_effect_clause(is_successful, is_tied, is_senate, chamber, other_chamber)
      if is_tied && is_senate
        "The votes were equally divided, so the question was lost. On this form of question that means " \
          "the amendments are not insisted on, because an equal vote shows they no longer command a " \
          "majority, and the bill proceeds without them. The chair of committees makes a statement " \
          "explaining the result when this happens."
      elsif is_successful
        "Agreeing to the motion means the #{chamber} dropped its own amendments, so the bill proceeds without them."
      else
        "This question was put as \"does not insist\", so defeating it is what insists on the amendments: " \
          "they stand, and the bill goes back to the #{other_chamber} with them."
      end
    end

    # Template 15 is the fallback, reached when no rule matched the question, so its sentence is
    # printed over every question the router could not place. Asserting that all of them record
    # an opinion and change no law was wrong for several real forms, approval of a legislative
    # instrument among them, which does the opposite (KNOWN_ISSUES.md, KI-4). It is now said
    # only where the motion's own words are declaratory.
    OPINION_MOTION_PATTERN = /
      \bis[ ]of[ ]the[ ]opinion\b | \bin[ ]the[ ]opinion[ ]of[ ]the\b |
      \b(?:house|senate|committee)[ ]+
      (?:notes|condemns|calls[ ]on|calls[ ]upon|believes|recognises|
      acknowledges|expresses|welcomes|deplores|regrets|affirms|declares)\b
    /xi

    def general_motion_effect_clause(extraction, template_id, chamber)
      return "" unless template_id == 15
      return "" unless extraction.motion_text.to_s.match?(OPINION_MOTION_PATTERN)

      " The motion records an opinion of the #{chamber} and has no legal effect."
    end

    # House Guide pp. 15-16: a defeated adjournment returns the chamber to the business it was
    # part way through, which is the half a reader is least likely to guess.
    def adjournment_effect_clause(template_id, is_successful, is_tied, chamber)
      return "" unless template_id == 26
      return "" if is_tied && chamber != "Senate"

      is_successful ? "The #{chamber} adjourned." : "The #{chamber} returned to the business it was part way through."
    end

    # How many members the chamber actually had on the day of the division, from TVFY's own
    # member records. Both thresholds below are fractions of that number, so deriving it beats
    # hardcoding a seat count against a date and then having to revisit the constant after
    # every redistribution (KNOWN_ISSUES.md, KI-8).
    #
    # nil when the answer isn't available - no house, no date, no database, or a members table
    # that has not been loaded - and the callers then fall back to the documented constants.
    def chamber_member_count(raw)
      supplied = raw[:chamber_size].to_i
      return supplied if supplied.positive?

      # Member.house holds the loader's own spellings, so a caller that passed a display name
      # ("House of Representatives") is mapped back before the lookup rather than silently
      # matching nothing and falling through to the constant.
      house = House.australian.find { |h| raw[:house].to_s.downcase.include?(h) }
      date = raw[:date]
      return nil if house.blank? || date.blank?
      return nil unless defined?(Member)

      count = Member.in_house(house).current_on(date).count
      count.positive? ? count : nil
    rescue StandardError
      nil
    end

    # The quorum is "at least one fifth of the whole number of the Members of the House"
    # (House of Representatives (Quorum) Act 1989), so it tracks the size of the House: 30 in
    # a House of 150, and 31 once the House grew to 151 at the 2019 election. House S.O. 58 is
    # what makes this worth reporting at all: if a division shows fewer than a quorum voting,
    # the House has not made a decision on the question.
    #
    # Returns nil when neither the member count nor the date is known, and the caller then says
    # nothing, because getting this wrong means telling a reader that a decision parliament did
    # make was never made. There is no Senate equivalent here on purpose: the Guides to Senate
    # Procedure set out no rule voiding a Senate division for want of a quorum, and a citation
    # we cannot check is not one to publish.
    def house_quorum_threshold(date_value, member_count = nil)
      return (member_count / 5.0).ceil if member_count

      date = begin
        date_value.is_a?(Date) ? date_value : Date.parse(date_value.to_s)
      rescue ArgumentError, TypeError
        nil
      end
      return nil unless date

      date >= HOUSE_OF_151_FROM ? 31 : 30
    end

    # More than half of all the members of the chamber. The House guide gives 76 for a House of
    # 150 and the Senate guide gives 39 of 76, which is what the constants below are; a known
    # member count supersedes them.
    HOUSE_ABSOLUTE_MAJORITY = 76
    SENATE_ABSOLUTE_MAJORITY = 39

    def absolute_majority_threshold(member_count, is_senate)
      return (member_count / 2) + 1 if member_count

      is_senate ? SENATE_ABSOLUTE_MAJORITY : HOUSE_ABSOLUTE_MAJORITY
    end

    # Which questions need an absolute majority rather than a majority of those voting.
    #
    # :always - section 128 of the Constitution on the third reading of a Constitution
    #   Alteration bill (House S.O. 173, Guide p. 77; Senate Guide No. 3), and rescinding an
    #   order of the Senate (Senate S.O. 87).
    # :conditional - a suspension of standing orders, where it depends on how the motion was
    #   moved: without notice it needs the absolute majority (House S.O. 47(c), Senate
    #   S.O. 209), but on notice, by leave, or under a contingent notice a simple majority is
    #   enough, and Senate Guide No. 5 says contingent notices are used for most suspensions
    #   precisely to avoid the higher bar. The question alone does not say which applied.
    def absolute_majority_requirement(template_id:, motion_text:, is_senate:, is_constitution_bill:, stage:)
      return :always if template_id == 6 && is_constitution_bill && stage.to_s.downcase == "third"
      return :always if is_senate && motion_text.to_s.match?(/\brescind(?:ed|ing)?\b/i)
      return :conditional if template_id == 17

      nil
    end

    # Said only where it changes what a reader should conclude: the ayes cleared a simple
    # majority but not the absolute one, so the recorded result and the requirement disagree.
    # Deciding between them is not something the pipeline can do from the question, so it says
    # what each says and sends the draft to a person (KNOWN_ISSUES.md, KI-5).
    def absolute_majority_notice(requirement:, aye_votes:, threshold:, chamber:, is_successful:)
      return "" if requirement.nil? || !is_successful
      return "" if aye_votes.zero? || threshold.nil? || aye_votes >= threshold

      case requirement
      when :always
        "Notice: this question needed an absolute majority, meaning at least #{threshold} of all the " \
        "members of the #{chamber} and not just of those voting. #{aye_votes} voted for it. The recorded " \
        "result and that requirement do not agree, so this summary needs checking against the official " \
        "record before it is relied on.\n"
      else
        "Notice: a motion to suspend standing orders moved without notice needs an absolute majority, " \
        "meaning at least #{threshold} of all the members of the #{chamber}. Moved on notice, by leave, " \
        "or under a contingent notice, a majority of those voting is enough. #{aye_votes} voted for this " \
        "one, so the result turns on which threshold applied, and the question alone does not record " \
        "which it was.\n"
      end
    end

    # Which reading a Template 6 division decided. Taken from the operative motion text, never
    # from the debate heading, so it cannot be captured by a heading covering a run of
    # business. Defaults to the second reading, the commoner of the two.
    def stage_from_motion(extraction)
      text = extraction.motion_text.to_s
      return "third" if text.match?(/read a third time|third reading/i)
      return "first" if text.match?(/read a first time|first reading/i)

      "second"
    end

    # What a Template 6 division decided, which takes both halves of the answer: the stage says
    # what the chamber was asked, and the result says whether it agreed. Reading the stage alone
    # is what let a defeated third reading compile to "the bill has now passed the Senate"
    # immediately after "which means it was unsuccessful" (KNOWN_ISSUES.md, KI-1).
    #
    # Any stage other than the second and third readings returns nothing rather than a guess. A
    # first reading belongs to Template 1, and in the House it happens without any question being
    # put at all (House of Representatives Guide to Procedures, p. 63), so there is nothing here
    # it would be honest to say about one.
    def bill_stage_clause(stage:, is_successful:, is_constitution_bill:, is_senate:, chamber:, other_chamber:,
                          originating_house: nil, absolute_majority_met: nil)
      case stage.to_s.downcase
      when "second"
        if is_successful
          "This means they agreed with the main idea of the bill and can now consider it in greater detail."
        else
          "This means the #{chamber} did not agree to the bill in principle, so it goes no further at this stage."
        end
      when "third"
        if is_constitution_bill
          constitution_alteration_clause(is_successful, is_senate, chamber, other_chamber, absolute_majority_met)
        elsif is_successful
          third_reading_passed_clause(chamber, other_chamber, originating_house)
        else
          "This means the bill did not pass the #{chamber}."
        end
      else
        ""
      end
    end

    # Where a bill goes once it passes a chamber depends on where it started, and TVFY does not
    # record that: the bills table carries official_id, url and title only. A bill that started
    # here goes to the other chamber; one that started there and passes unamended goes to the
    # Governor-General for assent, and one this chamber amended goes back with a schedule of
    # amendments (House Guide to Procedures, pp. 87-88). So the destination is stated only in the
    # case a supplied bill_originating_house settles outright, and is otherwise left unsaid. That
    # is a placeholder seam of the same shape as digest_section (ARCHITECTURE.md, section 15).
    def third_reading_passed_clause(chamber, other_chamber, originating_house)
      passed = "This means the bill has now passed the #{chamber}."
      return passed unless normalise_chamber(originating_house) == chamber

      "#{passed} It started in the #{chamber}, so it now goes to the #{other_chamber}."
    end

    # Maps whatever spelling of a chamber a caller supplied onto the two labels this class
    # publishes, so comparisons against `chamber` compare like with like. Anything unrecognised
    # is nil, which callers read as "not stated" rather than as a chamber.
    def normalise_chamber(value)
      text = value.to_s.downcase
      return "Senate" if text.include?("senate")
      return "House of Representatives" if text.match?(/representative|reps|\bhouse\b/)

      nil
    end

    # Section 128 of the Constitution requires a bill altering the Constitution to pass each
    # house by an absolute majority, a majority of all the members of the chamber rather than
    # of those voting. The two chambers record that differently: the House always rings the
    # bells for a division at the third reading "even when this question is carried on the
    # voices" (House S.O. 173), while in the Senate the bells are rung and the names recorded
    # in the Journals even if no division is called. So a Constitution Alteration division with
    # no votes against it is the rule working, not a pointless vote, and the summary says so.
    def constitution_alteration_clause(is_successful, is_senate, chamber, other_chamber, absolute_majority_met = nil)
      requirement = "Because this is a Constitution Alteration bill, Section 128 of the Constitution requires it to " \
                    "pass by an absolute majority, meaning a majority of all the members of the chamber and not just " \
                    "of those who voted."

      # Unlike a suspension, this requirement is unconditional, so a division recorded as
      # carried on fewer votes than it needs is a contradiction the summary must not resolve
      # in either direction. The notice beside the vote counts explains it (KNOWN_ISSUES.md,
      # KI-5); this clause simply stops short of asserting passage.
      if is_successful && absolute_majority_met == false
        return "#{requirement} Fewer members voted for the bill than that majority requires, so whether it passed " \
               "this stage does not follow from the division figures alone."
      end

      if is_successful
        recording = if is_senate
                      "The Senate records the names of senators voting on the third reading of such a bill even when no division is called, so that the constitutional majority is on the record."
                    else
                      "The House always rings the bells for a division at this stage, even when nobody opposes the bill, so that the constitutional majority is on the record."
                    end
        "This means the bill has now passed the #{chamber} and will go to the #{other_chamber}. #{requirement} #{recording}"
      else
        "#{requirement} The bill did not pass this stage."
      end
    end

    # Asks the database for the member the motion targets, so party, electorate and the
    # profile link come from TVFY records rather than from anything the model could
    # invent. Names or electorates the Hansard text never states resolve to a blank
    # ResolvedMember, which the target_* builders degrade to plain text.
    def resolve_target(raw, extraction)
      return unless [10, 23, 24].include?(extraction.template_id)

      MemberResolver.resolve(
        name: extraction.target_name.presence || raw[:target_name].presence,
        electorate: extraction.target_electorate.presence,
        house: raw[:house].presence,
        date: raw[:date].presence
      )
    end

    # Canonical name for template 10: the database spelling when matched, otherwise
    # whatever the Hansard text stated, otherwise the neutral fallback.
    def target_name_value(target, extraction, raw)
      return target.name if target&.name.present?

      extraction.target_name.presence || raw[:target_name].presence || "the member"
    end

    # Builds the template 23 target phrase so it can never render broken markdown: a
    # database match yields the full "Dickson MP [Name](link) (Party)" form, and every
    # fallback degrades to plain text naming the person the way Hansard stated it.
    def target_clause(target, extraction)
      return "the member" unless target&.member || extraction.target_name.present? || extraction.target_electorate.present?

      return linkified_target(target) if target&.member

      if extraction.target_electorate.present?
        "the honourable member for #{extraction.target_electorate}"
      else
        extraction.target_name.to_s
      end
    end

    def linkified_target(target)
      descriptor = if target.member.senator?
                     "Senator"
                   elsif target.electorate.present?
                     "#{target.electorate} MP"
                   else
                     "MP"
                   end
      party_part = target.party.present? ? " (#{target.party})" : ""
      "#{descriptor} [#{target.name}](#{target.link})#{party_part}"
    end

    def format_blockquote(text)
      return "> [No text recorded]" if text.blank?

      lines = text.to_s.strip.split("\n")
      formatted = lines.map do |line|
        stripped = line.strip
        if stripped.empty?
          ">"
        elsif stripped.start_with?(">")
          stripped
        else
          "> #{line}"
        end
      end
      formatted.join("\n")
    end

    # Only reached with claims that survived stage 4, so every dot point published here is
    # traceable to something the member actually said.
    def format_claims_blockquote(extraction)
      claims = extraction.mover_claims || []
      return "> [No explanatory claims recorded]" if claims.empty?

      points = claims.map do |c|
        claim_text = c.claim.to_s.strip.sub(/\.\z/, "")
        "> * #{claim_text}."
      end

      points.join("\n>\n")
    end

    private

    # Everything read here is a Type 1 authoritative fact (ARCHITECTURE.md, Data
    # classification): counts, dates, times and bill details from the database, with no AI
    # involvement. Accepts a Hash as well as a Division so the evaluation fixtures can drive
    # stage 5 without the database.
    def extract_attributes(division_or_data)
      if division_or_data.is_a?(Hash)
        norm = {}
        division_or_data.each { |k, v| norm[k.to_sym] = v }
        norm
      else
        div = division_or_data
        bills = div.respond_to?(:bills) ? div.bills.to_a : []
        bill = bills.first
        bill_name = if bills.size > 1
                      "#{bill&.title} (and #{bills.size - 1} related #{bills.size - 1 == 1 ? 'bill' : 'bills'})"
                    else
                      bill&.title
                    end

        # Majority calculation
        amount = "majority"
        turnout = 0
        if div.respond_to?(:division_info) && div.division_info
          turnout = div.division_info.turnout.to_i
          maj = div.division_info.majority.to_i
          amount = turnout.positive? && maj > (turnout / 2) ? "large majority" : "majority"
        end

        aye_votes = div.respond_to?(:aye_votes_including_tells) ? div.aye_votes_including_tells.to_i : 0
        no_votes = div.respond_to?(:no_votes_including_tells) ? div.no_votes_including_tells.to_i : 0
        turnout = aye_votes + no_votes if turnout.zero?

        result = if div.respond_to?(:passed?)
                   div.passed? ? "passed" : "negatived"
                 else
                   "negatived"
                 end

        is_tied = if div.respond_to?(:tied?)
                    div.tied?
                  else
                    turnout.positive? && aye_votes == no_votes
                  end

        is_free = div.respond_to?(:whips) && div.whips.any?(&:free?)

        {
          id: div.respond_to?(:id) ? div.id : nil,
          house: div.respond_to?(:house) ? div.house : "representatives",
          name: div.respond_to?(:name) ? div.name : "",
          date: div.respond_to?(:date) ? div.date.to_s : "",
          number: div.respond_to?(:number) ? div.number : 1,
          time: div.respond_to?(:clock_time) ? div.clock_time.to_s : "",
          clock_time: div.respond_to?(:clock_time) ? div.clock_time.to_s : "",
          aye_votes: aye_votes,
          no_votes: no_votes,
          turnout: turnout,
          rebellions: div.respond_to?(:rebellions) ? div.rebellions : 0,
          bill_name: bill_name,
          bill_link: bill&.url,
          amount: amount,
          result: result,
          tied: is_tied,
          free_vote: is_free
        }
      end
    end

    def resolve_mover_attributes(raw, extraction, is_senate)
      name = raw[:mover_name].presence
      link = raw[:mover_link].to_s
      party = raw[:mover_party].presence || raw[:party].to_s
      title = raw[:mover_title].presence || raw[:title].presence

      if name.blank?
        resolved_details = resolve_mover_from_claims(extraction, raw, is_senate)
        name = resolved_details[:name]
        link = resolved_details[:link]
        party = resolved_details[:party]
        title ||= resolved_details[:title]
      end

      # `resolved` is what lets a template leave the mover out altogether rather than naming
      # "a member". At the scheduled time the Speaker proposes the adjournment with nobody
      # moving it (House S.O. 31), so Template 26 has no mover to name and should not imply one.
      if name.blank?
        { name: "a member", link: "", party: "", title: "", resolved: false }
      else
        { name: name, link: link, party: party, title: title || (is_senate ? "Senator" : "Representative"),
          resolved: true }
      end
    end

    def resolve_mover_from_claims(extraction, raw, is_senate)
      mover_speaker = extraction.mover_claims&.map(&:speaker)&.find(&:present?)
      return {} if mover_speaker.blank?

      resolved = MemberResolver.resolve(
        name: mover_speaker,
        house: raw[:house].presence,
        date: raw[:date].presence
      )
      if resolved&.member
        {
          name: resolved.name,
          link: resolved.link,
          party: resolved.party,
          title: resolved.member.senator? ? "Senator" : "Representative"
        }
      else
        {
          name: mover_speaker,
          link: "",
          party: "",
          title: is_senate ? "Senator" : "Representative"
        }
      end
    end
  end
end
