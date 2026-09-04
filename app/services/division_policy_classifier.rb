# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

# Asks several Bedrock models to classify a Division against our existing Policies, or propose a
# new Policy if none fit (spike for openaustralia/theyvoteforyou#1716). Read-only - nothing here
# writes to the database, every result is a draft for a human to look at.
class DivisionPolicyClassifier
  # OAF prefers Australian-hosted infrastructure, so all three run from ap-southeast-2 rather than
  # the US regions Bedrock more commonly documents:
  # - Kimi K2.5 and DeepSeek were added to Sydney's open-weight lineup in AWS's Feb 2026 rollout,
  #   available on-demand like any other foundation model.
  # - Claude Haiku 4.5 isn't hosted in Sydney directly - it runs via an Australia-pinned
  #   cross-region inference profile (the "au." prefix) instead of a plain model id. UNVERIFIED:
  #   confirm this exact profile id against the Bedrock console once signed back into AWS - it's
  #   inferred from the "us."/"au." inference-profile naming convention, not confirmed directly.
  # - DeepSeek's model id may need to be deepseek.v3.2 rather than v3.1 for the Sydney rollout -
  #   also worth confirming against the console.
  MODELS = {
    "kimi-k2.5" => "moonshotai.kimi-k2.5",
    "deepseek-v3.2" => "deepseek.v3.2",
    "claude-haiku-4.5" => "au.anthropic.claude-haiku-4-5-20251001-v1:0"
  }.freeze

  REGION = "ap-southeast-2"

  EXAMPLES_PER_POLICY = 2
  MAX_EXAMPLES = 40

  Result = Struct.new(:model, :match, :policy, :direction, :new_policy_name, :new_policy_description,
                      :reasoning, :raw, :error, keyword_init: true) do
    def summary
      return "Error: #{error}" if error

      subject = match == "existing" ? "policy #{policy&.id}" : "new policy I propose"
      "#{direction == 'for' ? 'For' : 'Against'} #{subject}"
    end
  end

  def initialize(division, models: MODELS)
    @division = division
    @models = models
  end

  def classify_with_all_models
    @models.transform_values { |model_id| classify_with(model_id) }
  end

  def classify_with(model_id)
    response = client.converse(
      model_id: model_id,
      system: [{ text: system_prompt }],
      messages: [{ role: "user", content: [{ text: division_prompt }] }],
      inference_config: { temperature: 0 }
    )
    parse(model_id, response.output.message.content.first.text)
  rescue Aws::Errors::ServiceError => e
    Result.new(model: model_id, error: e.message)
  end

  private

  attr_reader :division

  def client
    @client ||= Aws::BedrockRuntime::Client.new(region: REGION)
  end

  def system_prompt
    <<~PROMPT
      You are helping classify Australian parliamentary divisions (votes) for the TheyVoteForYou
      website. Each Policy is a stance on an issue; a Division can be linked to a Policy as "for"
      (a supporter of the policy would vote aye) or "against" (a supporter would vote no).

      Given a division's motion text, decide:
      - If it clearly relates to one of the existing policies listed below, pick that policy's id
        and say whether this division represents a vote FOR or AGAINST it.
      - If none of the existing policies fit, propose a NEW policy: a short name and a
        one-sentence description, and say whether this division is FOR or AGAINST that new policy.

      Respond with JSON only, no other text, matching this shape exactly:
      {"match": "existing" or "new", "policy_id": <integer, only if match is "existing">,
       "new_policy_name": <string, only if match is "new">,
       "new_policy_description": <string, only if match is "new">,
       "direction": "for" or "against", "reasoning": "<one sentence>"}

      Existing policies:
      #{policy_list}

      Divisions already classified, for guidance:
      #{examples}
    PROMPT
  end

  def division_prompt
    <<~PROMPT
      Division: #{division.name}
      House: #{division.full_house_name}
      Date: #{division.date}

      Motion:
      #{division.motion}
    PROMPT
  end

  def policy_list
    Policy.published.order(:id).map { |policy| "#{policy.id}. #{policy.name} - #{policy.description}" }.join("\n")
  end

  def examples
    lines = []
    Policy.published.find_each do |policy|
      break if lines.size >= MAX_EXAMPLES

      policy.policy_divisions.includes(:division).limit(EXAMPLES_PER_POLICY).each do |policy_division|
        motion = policy_division.division.motion.to_s.truncate(300)
        lines << "- \"#{motion}\" -> policy #{policy.id} (#{policy.name}), #{direction_word(policy_division.vote)}"
      end
    end
    lines.join("\n")
  end

  def direction_word(vote)
    PolicyDivision.vote_without_strong(vote) == "aye" ? "for" : "against"
  end

  def parse(model_id, text)
    json = JSON.parse(text.sub(/\A```(?:json)?\n?/, "").sub(/```\s*\z/, "").strip)
    policy = Policy.find_by(id: json["policy_id"]) if json["match"] == "existing"
    Result.new(
      model: model_id,
      match: json["match"],
      policy: policy,
      direction: json["direction"],
      new_policy_name: json["new_policy_name"],
      new_policy_description: json["new_policy_description"],
      reasoning: json["reasoning"],
      raw: text
    )
  rescue JSON::ParserError => e
    Result.new(model: model_id, error: "Could not parse response: #{e.message}", raw: text)
  end
end
