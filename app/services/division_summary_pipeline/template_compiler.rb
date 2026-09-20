# frozen_string_literal: true

module DivisionSummaryPipeline
  # Stage 5: merges authoritative TVFY facts and validated extractions into one of the 23
  # human-curated Markdown templates in templates/, with no AI involvement.
  #
  # This is where the pipeline's guarantee is cashed in. Published sentences come from the
  # templates, numbers from the database, quoted passages from Hansard by way of stage 4, so
  # nothing here is generated and every part of the output is attributable. The awkward
  # details below are therefore grammar and degradation, not judgement: articles, duplicated
  # determiners, and falling back to plain text so an unresolved value cannot render as
  # broken Markdown in front of a reader.
  class TemplateCompiler
    DEFAULT_TEMPLATES_DIR = File.expand_path("templates", __dir__)

    def self.compile(division_or_data, extraction, digest_section: nil, templates_dir: nil)
      new(templates_dir: templates_dir).compile(division_or_data, extraction, digest_section: digest_section)
    end

    def initialize(templates_dir: nil)
      @templates_dir = templates_dir || DEFAULT_TEMPLATES_DIR
    end

    # An unknown placeholder renders as empty rather than being left in place, so a template
    # edited to use a key this class does not build degrades quietly instead of publishing
    # "{{whatever}}". ProvenanceValidator is what stops a required fact going missing here.
    def compile(division_or_data, extraction, digest_section: nil)
      template_text = load_template(extraction.template_id)
      data = prepare_compilation_data(division_or_data, extraction, digest_section)

      rendered = template_text.gsub(/\{\{([^}]+)\}\}/) do
        key = Regexp.last_match(1).strip
        data[key].nil? ? "" : data[key].to_s
      end

      # Normalise duplicate indefinite and definite articles (e.g. "a a majority" -> "a majority",
      # "to the the Selection of Bills Committee" -> "to the Selection of Bills Committee")
      rendered.gsub!(/\b([Aa]n?)\s+[Aa]n?\s+/, "\\1 ")
      rendered.gsub!(/\b([Tt]he)\s+the\s+/, "\\1 ")

      # Clean up excess consecutive newlines
      rendered.gsub!(/\n{3,}/, "\n\n")

      rendered.strip
    end

    # Templates are matched on the leading number alone ("6_passing_a_bill.md" is Template
    # 6); the rest of the file name is for people. Catalogue headings are kept out of the
    # files themselves so they can never leak into published output (ARCHITECTURE.md § 8).
    def load_template(template_id)
      pattern = File.join(@templates_dir, "#{template_id}_*.md")
      matching = Dir.glob(pattern)
      if matching.empty?
        raise Errno::ENOENT, "No template found for ID #{template_id} in #{@templates_dir}"
      end

      File.read(matching.first, encoding: "utf-8")
    end

    def prepare_compilation_data(division_or_data, extraction, digest_section)
      raw = extract_attributes(division_or_data)
      template_id = extraction.template_id

      # 1. Result and success phrasing. One list decides both: every template's intro sentence
      # reads "voted for/against ...", so any raw result spelling is normalised to those two
      # words here rather than interpolated as-is.
      result_raw = raw[:result].to_s.downcase
      is_successful = %w[passed agreed\ to for yes successful carried].include?(result_raw)
      successful_text = is_successful ? "successful" : "unsuccessful"
      result_phrasing = is_successful ? "for" : "against"

      # 2. Majority amount formatting. The article is computed rather than written into the
      # templates because the wording varies ("a majority", "an overwhelming majority").
      raw_amount = raw[:amount].presence || "majority"
      clean_amount = raw_amount.sub(/\A[Aa]n?\s+/, "").strip
      amount_with_article = clean_amount.downcase =~ /\A[aeiou]/ ? "an #{clean_amount}" : "a #{clean_amount}"

      # 3. Basic attributes. Nothing populates the mover fields for a live Division yet, so
      # outside the evaluation fixtures the name falls back to the debate heading and the
      # party and link render empty. Resolving the mover is open work (ARCHITECTURE.md § 13).
      time = raw[:time].presence || raw[:clock_time].to_s
      mover_name = raw[:mover_name].presence || raw[:name].to_s
      mover_link = raw[:mover_link].to_s
      mover_party = raw[:mover_party].presence || raw[:party].to_s
      mover_title = raw[:mover_title].presence || raw[:title].presence || "Representative"
      bill_name = raw[:bill_name].presence || extraction.topic
      bill_link = raw[:bill_link].to_s

      # 4. Rebellions text (members voting against their own party). Zero is stated rather
      # than omitted: silence would read as "not known" on a site people check for this.
      rebellions_val = raw[:rebellions]
      rebellions_text = if rebellions_val.is_a?(String) && rebellions_val.strip.present?
                          "#{rebellions_val.strip}\n"
                        elsif rebellions_val.is_a?(Integer) && rebellions_val.positive?
                          "#{rebellions_val} member(s) voted against their party.\n"
                        else
                          "Nobody voted against their party on this occasion.\n"
                        end

      # 5. Digest section. A Bills Digest is the Parliamentary Library's impartial summary of
      # a bill, which is why it can be quoted without attribution problems. Wording contract
      # comes from TEMPLATES.md (the original template document):
      # when a Bills Digest is found the section starts "According to the [Bill Digest](LINK):"
      # followed by the digest's key points as dot points; when no digest is found the fallback is a
      # blockquote containing exactly "No Bill Digest found." (no header, since there is nothing to
      # link to). Nothing populates these inputs yet - see "Hooking it up to live systems" in
      # ARCHITECTURE.md in this directory.
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

      # 6. Formatted motion and claims blockquotes
      formatted_motion = format_blockquote(extraction.motion_text)
      formatted_claims = format_claims_blockquote(extraction)

      # 7. Template 2 intro sentence, built here rather than in the template because its
      # ending inverts: an amendment declining the bill a second reading is an attempt to
      # stop the bill, so a vote for it was in effect a vote against it, while any other
      # second reading amendment leaves the text alone. Spelling this out is the point of the
      # template, since a reader has no way to tell the two apart from the vote alone.
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

      # 8. Chamber logic. What "passed" means to a reader depends on the stage: a second
      # reading agrees the bill's main idea and detailed consideration follows, while a third
      # reading sends the bill to the other chamber.
      house = raw[:house].to_s.downcase
      chamber = house.include?("senate") ? "Senate" : "House of Representatives"
      other_chamber = chamber == "Senate" ? "House of Representatives" : "Senate"

      stage_val = raw[:stage].presence || "second"
      stage_clause = if stage_val.to_s.downcase == "second"
                       "This means they agreed with the main idea of the bill and can now consider it in greater detail."
                     else
                       "This means the bill has now passed the #{chamber} and will go to the #{other_chamber}."
                     end

      # 9. Target resolution for the templates that name a second person (10, 23). The
      # extraction only supplies what the Hansard text states (a name and/or an
      # electorate); the database supplies the party, electorate and profile link,
      # keeping member details Type 1 authoritative facts with zero AI involvement
      # (ARCHITECTURE.md, Data classification section). Without this, an unresolved
      # target renders as broken markdown like "[Peter Dutton]() ()".
      target = resolve_target(raw, extraction)

      # One table for all 23 templates, each of which uses only the keys it needs.
      {
        "time" => time,
        "amount" => clean_amount,
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
        "amendment_effect_clause" => is_successful ? "The text of the bill has been changed accordingly." : "",
        "continuation_clause" => is_successful ? "They were unable to continue speaking. The debate on [#{bill_name}](#{bill_link}) continued." : "They were able to continue speaking.",
        "suspension_effect_clause" => is_successful ? "The usual rules were set aside so the matter could be dealt with immediately." : "",
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
        "followup_clause" => followup_clause(chamber, is_successful, raw[:followup_link])
      }
    end

    def followup_clause(chamber, is_successful, followup_link)
      return "" unless is_successful

      if followup_link.present?
        "The #{chamber} then voted on the question itself, which you can read about [here](#{followup_link})."
      else
        "The #{chamber} then voted on the question itself."
      end
    end

    # Asks the database for the member the motion targets, so party, electorate and the
    # profile link come from TVFY records rather than from anything the model could
    # invent. Names or electorates the Hansard text never states resolve to a blank
    # ResolvedMember, which the target_* builders degrade to plain text.
    def resolve_target(raw, extraction)
      return unless [10, 23].include?(extraction.template_id)

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
      unless target&.member || extraction.target_name.present? || extraction.target_electorate.present?
        return "the member"
      end

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

        # Majority calculation
        amount = "majority"
        if div.respond_to?(:division_info) && div.division_info
          turnout = div.division_info.turnout.to_i
          maj = div.division_info.majority.to_i
          amount = (turnout.positive? && maj > (turnout / 2)) ? "large majority" : "majority"
        end

        result = if div.respond_to?(:passed?)
                   div.passed? ? "passed" : "negatived"
                 else
                   "negatived"
                 end

        {
          id: div.respond_to?(:id) ? div.id : nil,
          house: div.respond_to?(:house) ? div.house : "representatives",
          name: div.respond_to?(:name) ? div.name : "",
          date: div.respond_to?(:date) ? div.date.to_s : "",
          number: div.respond_to?(:number) ? div.number : 1,
          time: div.respond_to?(:clock_time) ? div.clock_time.to_s : "",
          clock_time: div.respond_to?(:clock_time) ? div.clock_time.to_s : "",
          aye_votes: div.respond_to?(:aye_votes_including_tells) ? div.aye_votes_including_tells : 0,
          no_votes: div.respond_to?(:no_votes_including_tells) ? div.no_votes_including_tells : 0,
          rebellions: div.respond_to?(:rebellions) ? div.rebellions : 0,
          bill_name: bill&.title,
          bill_link: bill&.url,
          amount: amount,
          result: result
        }
      end
    end
  end
end

