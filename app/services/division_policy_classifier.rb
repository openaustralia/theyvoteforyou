# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

# DivisionPolicyClassifier asks several Bedrock models to classify a Division against our existing
# Policies, or propose a new Policy if none fit (spike for openaustralia/theyvoteforyou#1716). It's
# read-only: nothing here writes to the database, and every result is a draft for a human to look at.
class DivisionPolicyClassifier
  # OAF prefers Australian-hosted infrastructure, so all three models run from ap-southeast-2
  # instead of the US regions Bedrock more commonly documents. A direct check against `aws bedrock
  # list-foundation-models`/`list-inference-profiles` for ap-southeast-2 confirmed:
  # - Kimi K2.5 and DeepSeek V3.2 are ON_DEMAND foundation models there (AWS added them in its
  #   Feb 2026 Sydney open-weight rollout).
  # - Claude Haiku 4.5 is INFERENCE_PROFILE-only in this region: Sydney doesn't host it directly,
  #   so it runs via the Australia-pinned cross-region inference profile
  #   au.anthropic.claude-haiku-4-5-20251001-v1:0 instead of a plain model id.
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
      return "Error: model response was missing match/direction" if match.nil? || direction.nil?

      subject = match == "existing" ? "policy #{policy&.id}" : "new policy I propose"
      "#{direction == 'for' ? 'For' : 'Against'} #{subject}"
    end
  end

  # client: only for tests, to inject a stubbed Aws::BedrockRuntime::Client
  def initialize(division, models: MODELS, client: nil)
    @division = division
    @models = models
    @client = client
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
    # Models don't reliably follow the "JSON only" instruction - some wrap it in a code fence,
    # inconsistently, so pull out the object itself rather than trying to strip specific wrappers.
    json = JSON.parse(text[/\{.*\}/m] || text)
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
