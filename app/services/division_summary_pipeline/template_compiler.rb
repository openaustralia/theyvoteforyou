# frozen_string_literal: true

module DivisionSummaryPipeline
  # TemplateCompiler deterministically merges authoritative TVFY facts,
  # validated semantic extractions, and human-curated Markdown templates.
  class TemplateCompiler
    DEFAULT_TEMPLATES_DIR = File.expand_path("templates", __dir__)

    def self.compile(division_or_data, extraction, digest_section: nil, templates_dir: nil)
      new(templates_dir: templates_dir).compile(division_or_data, extraction, digest_section: digest_section)
    end

    def initialize(templates_dir: nil)
      @templates_dir = templates_dir || DEFAULT_TEMPLATES_DIR
    end

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

      # 2. Majority amount formatting
      raw_amount = raw[:amount].presence || "majority"
      clean_amount = raw_amount.sub(/\A[Aa]n?\s+/, "").strip
      amount_with_article = clean_amount.downcase =~ /\A[aeiou]/ ? "an #{clean_amount}" : "a #{clean_amount}"

      # 3. Basic attributes
      time = raw[:time].presence || raw[:clock_time].to_s
      mover_name = raw[:mover_name].presence || raw[:name].to_s
      mover_link = raw[:mover_link].to_s
      mover_party = raw[:mover_party].presence || raw[:party].to_s
      mover_title = raw[:mover_title].presence || raw[:title].presence || "Representative"
      bill_name = raw[:bill_name].presence || extraction.topic
      bill_link = raw[:bill_link].to_s

      # 4. Rebellions text
      rebellions_val = raw[:rebellions]
      rebellions_text = if rebellions_val.is_a?(String) && rebellions_val.strip.present?
                          "#{rebellions_val.strip}\n"
                        elsif rebellions_val.is_a?(Integer) && rebellions_val.positive?
                          "#{rebellions_val} member(s) voted against their party.\n"
                        else
                          "Nobody voted against their party on this occasion.\n"
                        end

      # 5. Digest section. Wording contract comes from TEMPLATES.md (the original template document):
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

      # 7. Template 2 Intro Sentence
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

      # 8. Chamber logic
      house = raw[:house].to_s.downcase
      chamber = house.include?("senate") ? "Senate" : "House of Representatives"
      other_chamber = chamber == "Senate" ? "House of Representatives" : "Senate"

      stage_val = raw[:stage].presence || "second"
      stage_clause = if stage_val.to_s.downcase == "second"
                       "This means they agreed with the main idea of the bill and can now consider it in greater detail."
                     else
                       "This means the bill has now passed the #{chamber} and will go to the #{other_chamber}."
                     end

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
        "target_name" => raw[:target_name] || "the member",
        "target_link" => raw[:target_link] || "",
        "target_party" => raw[:target_party] || "",
        "target_electorate" => raw[:target_electorate] || "",
        "committee_name" => raw[:committee_name] || "",
        "business_name" => raw[:business_name] || "",
        "motion_link" => raw[:motion_link] || "",
        "rearrangement_description" => raw[:rearrangement_description] || "",
        "regulation_name" => raw[:regulation_name] || "",
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

