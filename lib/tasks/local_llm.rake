# frozen_string_literal: true

# Runs the AI division summary pipeline against a llama.cpp server on your own machine instead
# of Bedrock, for testing a change without AWS credentials. Development only: nothing in
# production calls it.
#
# It uses the seams the pipeline already has rather than changing it:
# - SemanticExtractor.new(llm_caller:) swaps the Bedrock `converse` call for any callable
#   taking (system_prompt, user_prompt) and returning the model's reply text.
# - DivisionSummarizer.new(models:, extractor:) runs every other stage unchanged.
#
# llama-server's OpenAI-compatible endpoint is documented at
# https://github.com/ggml-org/llama.cpp/tree/master/tools/server
namespace :ai do
  desc "LOCAL: run the AI division summary pipeline against llama-server instead of Bedrock. " \
       "DIVISION_ID=<id> required; LLAMA_URL defaults to http://127.0.0.1:8080."
  # Unlike ai:summarize_division this always re-runs and overwrites the saved draft, since the
  # point of a local run is to see the effect of a change.
  task summarize_division_local: :environment do
    require "net/http"

    division_id = ENV.fetch("DIVISION_ID") { abort "Usage: rake ai:summarize_division_local DIVISION_ID=123" }
    base_url = ENV.fetch("LLAMA_URL", "http://127.0.0.1:8080").chomp("/")
    # A long debate on local hardware can take many minutes just to read the prompt.
    read_timeout = ENV.fetch("LLAMA_TIMEOUT", "3600").to_i
    # A small model at temperature 0 can get stuck and never finish: Gemma 4 12B wrote 113,000
    # tokens for division 122 before the timeout cut it off. The answer itself is a few hundred
    # tokens of JSON plus any thinking, so a cap turns an hour-long hang into a quick failure.
    max_tokens = ENV.fetch("LLAMA_MAX_TOKENS", "16000").to_i
    # Every reply is kept, thinking included, so a failed run can still be read afterwards.
    replies_dir = Rails.root.join("tmp/llm_replies")

    post_json = lambda do |path, body|
      uri = URI("#{base_url}#{path}")
      response = Net::HTTP.start(uri.host, uri.port, read_timeout: read_timeout) do |http|
        http.post(uri.path, body.to_json, "Content-Type" => "application/json")
      end
      raise "llama-server #{response.code}: #{response.body.to_s.truncate(500)}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    # Named after the loaded GGUF so local drafts never share an AiDivisionSummary row with a
    # Bedrock model's, and the Reviewer Only report says which file wrote it.
    loaded = begin
      JSON.parse(Net::HTTP.get(URI("#{base_url}/v1/models"))).dig("data", 0, "id")
    rescue SystemCallError => e
      abort "Can't reach llama-server at #{base_url} (#{e.message}). Start it first, or set LLAMA_URL."
    end
    model_id = "llamacpp.#{File.basename(loaded.to_s, '.gguf').presence || 'local'}"

    # Temperature 0 to match the Bedrock call. Reasoning models' thinking normally comes back in
    # reasoning_content; the strip covers a server started with --reasoning-format none.
    llm_caller = lambda do |system_prompt, user_prompt|
      reply = post_json.call("/v1/chat/completions",
                             messages: [{ role: "system", content: system_prompt },
                                        { role: "user", content: user_prompt }],
                             temperature: 0, max_tokens: max_tokens)
      FileUtils.mkdir_p(replies_dir)
      stamp = "division-#{division_id}-#{Time.current.strftime('%Y%m%d-%H%M%S')}"
      saved = replies_dir.join("#{stamp}.json")
      File.write(saved, JSON.pretty_generate(reply))
      # The draft keeps only the prompt of the reply it used, so a sitting day retry's first
      # prompt would otherwise be lost.
      File.write(replies_dir.join("#{stamp}-prompt.json"), JSON.pretty_generate(system: system_prompt, user: user_prompt))
      puts "Model reply saved to #{saved.relative_path_from(Rails.root)}, and its prompt beside it"
      if reply.dig("choices", 0, "finish_reason") == "length"
        raise "model wrote #{max_tokens} tokens without finishing (LLAMA_MAX_TOKENS); " \
              "see #{saved.relative_path_from(Rails.root)}"
      end

      reply.dig("choices", 0, "message", "content").to_s.gsub(%r{<think>.*?</think>}m, "").strip
    end

    division = Division.find(division_id)
    extractor = DivisionSummaryPipeline::SemanticExtractor.new(llm_caller: llm_caller)
    summarizer = DivisionSummarizer.new(division, models: { "local" => model_id }, extractor: extractor)

    puts "Division ##{division.id}: #{division.name}"
    puts "Model: #{model_id} at #{base_url}"
    puts

    summary = AiDivisionSummary.save_from_result!(division, summarizer.summarize_with(model_id))
    if summary.error
      puts "Error: #{summary.error}"
    else
      puts "Title: #{summary.title}"
      puts "Description: #{summary.description}"
    end
  end
end
