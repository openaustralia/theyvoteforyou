# frozen_string_literal: true

require "aws-sdk-bedrockruntime"
require "json"

module DivisionSummaryPipeline
  # Stage 3: the pipeline's only LLM call, prompting strictly for structured JSON.
  #
  # The model is used as a semantic sensor, for the one job deterministic code cannot do:
  # reading what a debate was about. It is trusted with nothing else. It writes no published
  # prose, supplies no numbers, and every quote it returns is checked against Hansard by
  # stage 4 before any of it is compiled, so a wrong answer here is caught rather than
  # printed.
  class SemanticExtractor
    REGION = "ap-southeast-2"

    def initialize(model_id = nil, client: nil, llm_caller: nil)
      @model_id = model_id
      @bedrock_client = client
      @llm_caller = llm_caller
    end

    # Runs the model and returns its raw response text. Kept separate from #extract so the
    # orchestrator can keep the raw response for the AiDivisionSummary record while the
    # parsing itself happens through ExtractionPayload.
    def extract_raw(context_packet)
      user_prompt = build_user_prompt(context_packet)

      if @llm_caller
        @llm_caller.call(system_prompt, user_prompt)
      else
        call_bedrock(user_prompt)
      end
    end

    # Runs the model and parses its response into an ExtractionPayload (nil if unparseable).
    def extract(context_packet)
      ExtractionPayload.from_json(extract_raw(context_packet))
    end

    # Tagged sections rather than prose: models attend to delimited blocks more reliably, and
    # the Speaker's Question leads because rule 1 of the system prompt tells the model to read
    # everything else in light of it.
    def build_user_prompt(packet)
      sections = []
      sections << "<speaker_question>\n#{packet.speaker_question.to_s.strip}\n</speaker_question>"

      meta = packet.division_metadata || {}
      meta_lines = [
        "Date: #{packet.date}",
        "House: #{packet.house}",
        "Time: #{packet.clock_time}",
        "Division Title: #{meta[:name]}",
        "Votes: #{meta[:aye_votes] || 0} Yes - #{meta[:no_votes] || 0} No"
      ]
      sections << "<division_metadata>\n#{meta_lines.join("\n")}\n</division_metadata>"

      # The model is asked to respect stage 2's fence (system prompt rule 2), and
      # ProvenanceValidator#check_routing_fence rejects the extraction if it did not.
      if packet.procedural_decision
        decision = packet.procedural_decision
        cand_str = decision.candidate_templates.join(", ")
        locked_str = decision.locked_out_templates.join(", ")
        routing_note = "Rule: #{decision.rule_name}. Candidates: [#{cand_str}]."
        routing_note += " Disallowed Templates: [#{locked_str}]." if locked_str.present?
        sections << "<procedural_routing_guidance>\n#{routing_note}\n</procedural_routing_guidance>"
      end

      sections << "<official_summary>\n#{packet.official_summary.to_s.strip}\n</official_summary>" if packet.official_summary.present?

      sections << "<hansard_context>\n#{packet.hansard_context.to_s.strip}\n</hansard_context>"

      sections.join("\n\n")
    end

    # Treat this prompt as source code: editing a rule changes every future extraction, and
    # several rules are load-bearing rather than stylistic. Rule 5 (a verbatim quote per
    # claim) is what makes stage 4's verification possible at all, rule 9 restates the
    # guillotine trap the router already fences, rule 6 is the non-partisanship OAF requires,
    # and rule 11 keeps member details out of the model's hands because MemberResolver looks
    # them up in the database.
    def system_prompt
      <<~PROMPT
        You are the Semantic Extractor for They Vote For You (theyvoteforyou.org.au), a project of
        the non-partisan OpenAustralia Foundation. Your role is NOT to write prose, titles, or
        summaries. You act purely as a semantic extraction engine reading Australian parliamentary
        records into strict JSON.

        Follow these procedural rules:
        1. ANCHOR ON THE SPEAKER'S QUESTION:
           The definitive procedural truth of any division is the Speaker's Question ("The question is that...").
           Inspect <speaker_question> to determine what is being decided.

        2. OBEY PROCEDURAL ROUTING GUIDANCE:
           - You MUST choose a template_id from <procedural_routing_guidance> candidate templates if provided.
           - You MUST NEVER select a template listed under Disallowed Templates.

        3. THE TEMPLATE CATALOGUE (template_id 1 to 23):
            1: First Reading
            2: Second Reading Amendment (e.g. "That all words after 'That' be omitted with a view to substituting...")
            3: In Committee Amendment (Senate)
            4: Consideration in Detail (House of Representatives)
            5: Report from Federation Chamber
            6: Passing a Bill (Second or Third Reading)
            7: Agreeing to Amendments / Consideration of a Message
            8: Order for the Production of Documents
            9: Disallowance Motion
           10: Censure Motion
           11: Budget Estimates Committees
           12: Establishing a Select Committee
           13: Committee Referral
           14: Selection of Bills Committee Report
           15: General Motion
           16: Matter of Urgency (Senate)
           17: Suspension of Standing Orders
           18: Limitation of Debate (Guillotine)
           19: Rearrangement of Business
           20: Withdrawal of Business
           21: Parliamentary Zone Proposed Works
           22: Closure of Debate ("That the question be now put")
           23: Member Be No Longer Heard (House of Representatives)

        4. OPERATIVE MOTION TEXT:
           Extract the exact operative wording of the motion or amendment as put to the chamber from the Hansard context.

        5. MOVER CLAIMS WITH VERBATIM EVIDENCE:
           Extract 1 to 4 functional points made by the mover explaining the amendment or motion.
           CRITICAL: Every claim MUST be accompanied by a verbatim quote from <hansard_context> in the 'evidence' field.
           If a claim cannot be quoted verbatim from the text, DO NOT INCLUDE IT.
           If the mover did not give a separate speech in the provided excerpt (for example the amendment was
           moved formally), draw the functional claims strictly from the operative clauses of the amendment or
           motion itself, attributed to the mover.
           Scope claims to what the vote itself decides, never the subject it happens to sit under:
           - Template 8 (Production of Documents): claims are about why the documents should be produced and
             released. They are never about the subject matter the documents deal with.
           - Template 17 (Suspension of Standing Orders): claims are about why the rules should be set aside
             so something can happen now, not about the merits of that underlying matter.
           - Template 18 (Limitation of Debate): claims are about the time limit and the remaining stages,
             not about the business being limited.
           - Template 9 (Disallowance): claims describe what the regulation does and why it should stop
             having legal force. Regulations are law made under powers an Act gives the government.
           - Templates 22 and 23 (Closure, Member Be No Longer Heard): these decide only that debate ends or
             a speaker sits down, so make no claims about the underlying question.

        6. NEUTRALITY IS NOT OPTIONAL:
           Claims describe the procedure and record facts in plain, functional terms. Never characterise a vote
           as good, bad, hypocritical or surprising, and never imply support for or opposition to any party,
           candidate or position.

        7. TEMPLATE 2 (SECOND READING AMENDMENT):
           If template_id is 2, you MUST set 'declines_second_reading' to true if the amendment explicitly
           declines a second reading ("declining to give the bill a second reading..."). An amendment worded
           "whilst not declining to give the bill a second reading..." is false.

        8. CONTEXT SUFFICIENCY AND RESUMED DEBATES:
           Debate is frequently adjourned and later resumed, so an excerpt can begin mid-conversation with the
           mover's opening speech sitting earlier in the sitting day or on a previous sitting day. If the
           provided excerpt lacks the mover's speech or the motion details, set 'sufficient_context' to false
           and state 'missing_context_clue' (for example: "mover's opening speech may be earlier in this
           sitting day's debate or on a previous sitting day"). Do not reconstruct a missing speech from
           inference; extract only what the excerpt supports.

        9. DEBATE HEADINGS ARE NOT VOTES:
           A debate heading such as "Limitation of Debate" describes a stretch of business, not each division
           under it. Substantive amendment and bill votes are routinely held under such a heading. Anchor on
           <speaker_question> for what is being decided, and never select Template 18 for a question that is
           not itself about limiting the time for debate.

        10. LANGUAGE:
           Write claims in Australian English (-ise, -our spellings) and standard Australian parliamentary
           terminology. Do not use em dashes in your own prose; quoted Hansard text is reproduced exactly as
           it appears, including any em dashes.

        11. TEMPLATE-SPECIFIC FACTS:
           Some templates render one specific fact in the summary sentence. Extract it only when the
           <hansard_context> states it; otherwise set it to null. Copy names, electorates and titles
           verbatim. NEVER produce a URL, a link, a party affiliation, or an electorate or title the text
           does not state - the pipeline looks those up in its own database from what you extract.
           - Template 9 (Disallowance): 'regulation_name' is the legislative instrument the motion
             would disallow.
           - Template 10 (Censure): 'target_name' is the member or minister the motion censures or
             expresses want of confidence in.
           - Template 13 (Committee Referral): 'committee_name' is the committee the matter is referred to.
           - Template 19 (Rearrangement of Business): 'rearrangement_description' is what happens to the
             business, in the motion's operative words.
           - Template 20 (Withdrawal of Business): 'business_name' is the item withdrawn from the
             Notice Paper.
           - Template 23 (Member Be No Longer Heard): give 'target_electorate' when the motion names
             the electorate ("the honourable member for Dickson" yields target_electorate "Dickson")
             and 'target_name' when the Hansard text states the member's name.

        Respond ONLY with a valid JSON object matching this schema. Do not enclose in markdown fences or include commentary:
        {
          "template_id": 1 to 23,
          "topic": "Concise 2-5 word description",
          "motion_text": "Exact operative motion text",
          "mover_claims": [
            {
              "claim": "Clear functional summary in Australian English",
              "evidence": "Verbatim quote from hansard_context proving claim",
              "speaker": "Name of speaker"
            }
          ],
          "target_name": "member or minister the motion targets, verbatim, or null",
          "target_electorate": "electorate of the targeted member, verbatim, or null",
          "committee_name": "committee the motion concerns, verbatim, or null",
          "regulation_name": "legislative instrument the motion disallows, verbatim, or null",
          "business_name": "business withdrawn from the Notice Paper, verbatim, or null",
          "rearrangement_description": "what happens to the business, verbatim, or null",
          "declines_second_reading": true, false, or null,
          "sufficient_context": true or false,
          "missing_context_clue": null or "description of missing context"
        }
      PROMPT
    end

    private

    # Lazy so nothing contacts AWS at boot or under test.
    def bedrock_client
      @bedrock_client ||= Aws::BedrockRuntime::Client.new(region: REGION)
    end

    # Temperature 0 because this is extraction, not writing: re-running a division should
    # give as near the same answer as the model allows, so a reviewer can tell a changed
    # summary from a differently-worded one.
    def call_bedrock(user_prompt)
      response = bedrock_client.converse(
        model_id: @model_id,
        system: [{ text: system_prompt }],
        messages: [{ role: "user", content: [{ text: user_prompt }] }],
        inference_config: { temperature: 0 }
      )
      response.output.message.content.first.text
    end
  end
end
