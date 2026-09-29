# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::ExtractionPrompt do
  let(:question) { "The question is that the second reading amendment moved by Senator Treloar on sheet 9001 be agreed to." }
  let(:mover) do
    summary_speech(<<~XML, id: "s1", name: "Morgan Treloar", gid: "uk.org.publicwhip/lord/900001", time: "13:20")
      <p>Rural students pay more to study.</p>
      <p>I move the second reading amendment on sheet 9001:</p>
      <p class="italic">At the end of the motion, add ", but the Senate notes the cost".</p>
    XML
  end
  let(:chair) { summary_speech("<p>#{question}</p>", id: "s2", name: "Robin Castellan", gid: "uk.org.publicwhip/lord/900002", time: "13:30") }
  let(:routing) { DivisionSummaryPipeline::RoutingDecision.fenced([2, 29], rule_name: "SECOND_READING_NUANCE", reason: "test") }

  def prompt_for(speeches: [mover, chair], routing: self.routing, warnings: [])
    described_class.user_prompt(summary_packet(speeches: speeches, question: question, routing: routing, warnings: warnings))
  end

  describe ".user_prompt" do
    it "leads with the question and shows the transcript with an ID on every unit" do
      prompt = prompt_for

      expect(prompt).to start_with("<speaker_question>\n#{question}\n</speaker_question>")
      expect(prompt).to include("[S1.1] Rural students pay more to study.", "[S1.3 motion] At the end of the motion",
                                "[S2.1 chair] The question is", "DIVISION [1:31 PM]")
    end

    it "tells the model the motion is settled when Stage 1 found it, and whose sentences can explain it" do
      expect(prompt_for).to include("Moved by: Morgan Treloar (speech S1).", "Introduced in: S1.2.",
                                    "Terms moved: S1.3. The motion is settled", "An explanation can only be sentences Morgan Treloar spoke.")
    end

    it "asks for the motion's paragraphs only when Stage 1 could not find it" do
      silent = summary_speech("<p>Rural students pay more to study.</p>", id: "s1", name: "Morgan Treloar",
                                                                          gid: "uk.org.publicwhip/lord/900001", time: "13:20")

      expect(prompt_for(speeches: [silent, chair])).to include("The terms moved were not found by rule.", "\"operative_motion\" as missing")
    end

    # Told to report the terms missing, a model did so for a question that is the whole motion,
    # and the orchestrator read the whole sitting day looking for terms that do not exist.
    it "tells the model there are no terms to find when the question is the whole motion" do
      passing = "The question now is that the remaining stages of the bill be agreed to, and the bill be now passed."
      chair_only = [summary_speech("<p>#{passing}</p>", id: "s1", name: "Robin Castellan",
                                                        gid: "uk.org.publicwhip/lord/900002", time: "13:30")]
      settled = DivisionSummaryPipeline::ProceduralRouter.route(speaker_question: passing, chamber: "senate")
      prompt = described_class.user_prompt(summary_packet(speeches: chair_only, question: passing, routing: settled))

      expect(prompt).to include("is the whole motion", "do not report \"operative_motion\" as missing")
      expect(prompt).not_to include("If they are not, leave it empty")
    end

    # KNOWN_ISSUES.md KI-23: "MUST choose from the candidates" turned the fallback's default into a fence nothing checks.
    it "says when the allowed templates are only a default, and never softens an enforced fence" do
      advisory = DivisionSummaryPipeline::RoutingDecision.default([15], rule_name: "GENERAL_MOTION_FALLBACK", reason: "test")

      expect(prompt_for(routing: advisory)).to include("These are a default, not a constraint")
      expect(prompt_for).to include("Allowed templates: [2, 29]. Choose one of these.")
      expect(prompt_for).not_to include("default, not a constraint")
    end

    it "names forbidden templates and settles a deterministic route" do
      settled = DivisionSummaryPipeline::RoutingDecision.settled(22, rule_name: "CLOSURE_OF_DEBATE", reason: "test")
      guarded = DivisionSummaryPipeline::RoutingDecision.fenced([2, 3], rule_name: "GUILLOTINE_TRAP_AVOIDED", reason: "test",
                                                                        forbidden: [18])

      expect(prompt_for(routing: settled)).to include("set template_id to 22")
      expect(prompt_for(routing: guarded)).to include("Forbidden templates: [18].")
    end

    it "passes Stage 1's context warnings in their own block" do
      expect(prompt_for(warnings: ["This division was deferred."])).to include("<context_warnings>\n- This division was deferred.\n</context_warnings>")
    end
  end

  describe ".system_prompt" do
    subject(:prompt) { described_class.system_prompt }

    it "lists every template from the catalogue" do
      DivisionSummaryPipeline::TemplateCatalogue.entries.each do |entry|
        expect(prompt).to include(format("%<id>2d: %{prompt}", id: entry.id, prompt: entry.prompt))
      end
    end

    it "asks for selections, never text for publication" do
      expect(prompt).to include("You never write text for publication", "NEUTRALITY IS NOT OPTIONAL",
                                "never a \"move\", \"motion\" or", "return an empty list")
      expect(prompt).not_to include("topic", "Australian English (-ise")
    end

    it "keeps the closed list of reasoned amendment forms (KNOWN_ISSUES.md, KI-11)" do
      expect(prompt).to include("whilst not declining to give the bill a second reading", "they are false, not true")
    end

    it "describes each fact a template names, and the closed list of missing evidence" do
      expect(prompt).to include("Template 13 (Committee Referral): 'committee_name' is the committee the matter is referred to.")
      DivisionSummaryPipeline::ExtractionPayload::MISSING_EVIDENCE.each_key { |kind| expect(prompt).to include("\"#{kind}\"") }
    end
  end
end
