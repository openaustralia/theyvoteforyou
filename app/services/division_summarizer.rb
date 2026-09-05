# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

# DivisionSummarizer asks several Bedrock models to write a plain-language title and description
# for a Division, matching the style used for existing edited divisions (spike for
# openaustralia/theyvoteforyou#1716). It's read-only: nothing here writes to the database - every
# result is a draft for a human to review via the existing WikiMotion edit form, same as if a
# person had written it.
class DivisionSummarizer
  # Deliberately its own copy rather than DivisionPolicyClassifier::MODELS - tuning one service's
  # model lineup (e.g. dropping a model that classifies poorly) shouldn't silently change the
  # other's, even though they happen to use the same three models today.
  MODELS = DivisionPolicyClassifier::MODELS.dup.freeze
  REGION = DivisionPolicyClassifier::REGION

  Result = Struct.new(:model, :title, :description, :raw, :error, keyword_init: true)

  # client: only for tests, to inject a stubbed Aws::BedrockRuntime::Client
  def initialize(division, models: MODELS, client: nil)
    @division = division
    @models = models
    @client = client
  end

  def summarize_with_all_models
    @models.transform_values { |model_id| summarize_with(model_id) }
  end

  def summarize_with(model_id)
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
      You are writing plain-language summaries of Australian parliamentary divisions (votes) for
      the TheyVoteForYou website, replacing the formal Hansard record with something a member of
      the public can actually understand.

      Follow this style guide:
      - Plain English: avoid jargon, buzzwords, and long or formal words - use "help" not
        "assist", "about" not "approximately".
      - Active voice, not passive - "they voted for the bill", not "the bill was voted for".
      - Be specific, informative, clear, and concise. Serious but not pompous.
      - Emotionless: no subjective adjectives, and strictly non-partisan - never use language that
        favours one side of politics, and never imply the vote's outcome was good, bad, or
        surprising.
      - Use contractions (can't, don't, they'll).
      - No sentence over 25 words.
      - Gender-neutral language (they/them/their).
      - Front-load the most important information first.

      Produce two things:
      - A "title" following the same structure as existing titles on the site - "<Category> —
        <Subject>" or "<Category> — <Subject>; <Stage>", for example "Bills — Higher Education
        Support Amendment Bill 2026; Second Reading" or "Motions — Cost of Living". Editors tidy
        the wording but keep this same shape - don't invent a different structure.
      - A "description": one or two short paragraphs in plain English explaining what this
        division actually decided, for someone with no background in parliamentary procedure.

      Respond with JSON only, no other text, matching this shape exactly:
      {"title": "<string>", "description": "<string>"}
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

  def parse(model_id, text)
    json = JSON.parse(text[/\{.*\}/m] || text)
    usable = json.is_a?(Hash) && json["title"].present? && json["description"].present?
    return Result.new(model: model_id, error: "Model response was missing title/description", raw: text) unless usable

    Result.new(model: model_id, title: json["title"], description: json["description"], raw: text)
  rescue JSON::ParserError => e
    Result.new(model: model_id, error: "Could not parse response: #{e.message}", raw: text)
  end
end
