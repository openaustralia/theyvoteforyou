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

  # A change to what Stage 1 reads or Stage 2 decides can move divisions that no spec covers, so
  # routes are compared before and after over every loaded division (KNOWN_ISSUES.md KI-35).
  desc "LOCAL: record what Stages 1 and 2 decide for every loaded division in a date range. " \
       "LABEL=<name> required; FROM and TO default to the last 150 days."
  task route_snapshot: :environment do
    label = ENV.fetch("LABEL") { abort "Usage: rake ai:route_snapshot LABEL=before [FROM=2026-05-01 TO=2026-09-30]" }
    to = Date.parse(ENV.fetch("TO", Date.current.to_s))
    from = Date.parse(ENV.fetch("FROM", (to - 150).to_s))
    cache = LocalHansardCache.new
    divisions = Division.where(date: from..to).order(:date, :house, :number)

    rows = divisions.map do |division|
      print "."
      packet = DivisionSummaryPipeline::ContextBuilder.build(division, xml_content: cache.raw(division.house, division.date),
                                                                       xml_fetcher: cache.fetcher)
      LocalHansardCache.snapshot_row(division, packet)
    rescue StandardError => e
      { id: division.id, house: division.house, date: division.date.to_s, number: division.number, error: e.message }
    end
    puts

    out = Rails.root.join("tmp/route_snapshots/#{label}.json")
    FileUtils.mkdir_p(out.dirname)
    File.write(out, JSON.pretty_generate(rows))
    puts "#{rows.size} divisions from #{from} to #{to} written to #{out.relative_path_from(Rails.root)}"
  end

  desc "LOCAL: print every division whose Stage 1 or Stage 2 result differs between two route snapshots. " \
       "BEFORE=<label> AFTER=<label> required."
  task route_snapshot_diff: :environment do
    read = lambda do |name|
      label = ENV.fetch(name) { abort "Usage: rake ai:route_snapshot_diff BEFORE=before AFTER=after" }
      JSON.parse(Rails.root.join("tmp/route_snapshots/#{label}.json").read).index_by { |row| row["id"] }
    end
    before = read.call("BEFORE")
    after = read.call("AFTER")

    changed = (before.keys | after.keys).sort.filter_map do |id|
      old = before[id] || {}
      new = after[id] || {}
      fields = (old.keys | new.keys).reject { |key| old[key] == new[key] }
      next if fields.empty?

      row = old.presence || new
      lines = fields.map { |key| "    #{key}: #{old[key].inspect} -> #{new[key].inspect}" }
      "#{row['house']} #{row['date']} ##{row['number']} (id #{id})\n#{lines.join("\n")}"
    end
    puts changed.empty? ? "No division changed." : changed.join("\n\n")
    puts "\n#{changed.size} of #{after.size} divisions changed." if changed.any?
  end

  # Most pipeline fixes can be checked without a model: the model's answer is a list of IDs and
  # a template number, so replaying an answer it already gave reruns Stages 1, 2, 4 and 5 on
  # today's code. Nothing is saved.
  desc "LOCAL: rebuild a draft from a model reply saved in tmp/llm_replies, on today's code. " \
       "FILE=<reply> required; RETRY=<reply> answers the sitting day retry, if the draft asks for one."
  task replay_reply: :environment do
    files = [ENV.fetch("FILE") { abort "Usage: rake ai:replay_reply FILE=tmp/llm_replies/division-23-....json [RETRY=...]" },
             ENV.fetch("RETRY", nil)].compact
    replies = files.map { |file| JSON.parse(File.read(file)) }
    division_id = ENV.fetch("DIVISION_ID") { File.basename(files.first)[/\Adivision-(\d+)-/, 1] }
    model_id = "llamacpp.#{File.basename(replies.first['model'].to_s, '.gguf').presence || 'local'}"
    answers = replies.map do |reply|
      reply.dig("choices", 0, "message", "content").to_s.gsub(%r{<think>.*?</think>}m, "").strip
    end
    llm_caller = lambda do |_system_prompt, _user_prompt|
      answers.shift || raise("no saved reply for this call (pass RETRY=<file> to answer the sitting day retry)")
    end

    division = Division.find(division_id)
    cache = LocalHansardCache.new
    extractor = DivisionSummaryPipeline::SemanticExtractor.new(llm_caller: llm_caller)
    summarizer = DivisionSummarizer.new(division, models: { "local" => model_id }, extractor: extractor,
                                                  xml_content: cache.raw(division.house, division.date),
                                                  xml_fetcher: cache.fetcher)
    result = summarizer.summarize_with(model_id)
    puts "Division ##{division.id}: #{division.name}"
    puts "Replayed: #{files.join(', ')}"
    puts "Error: #{result.error}" if result.error
    puts "Title: #{result.title}"
    puts "Description: #{result.description}"
  end
end

# Sitting days' ParlParse XML for the tasks above, fetched once through the loader's own fetch
# (ARCHITECTURE.md section 5) and kept under tmp/hansard_xml. EarlierDebate looks back up to 70
# calendar days for every division, so without this a snapshot takes hours; and because every run
# then reads the same Hansard, two snapshots taken with no code change between them agree.
class LocalHansardCache
  def initialize
    @dir = Rails.root.join("tmp/hansard_xml")
    @documents = {}
    FileUtils.mkdir_p(@dir)
  end

  # The day's XML as text, or nil for a day with none (a non-sitting day is a 404).
  def raw(house, date)
    file = @dir.join("#{house}-#{date}.xml")
    missing = @dir.join("#{house}-#{date}.missing")
    return nil if missing.exist?
    return file.read if file.exist?

    document = DataLoader::Debates.fetch_xml_document(house, date.to_s)
    unless document
      FileUtils.touch(missing)
      return nil
    end

    file.write(document.to_xml)
    file.read
  end

  # The xml_fetcher ContextBuilder takes for earlier sitting days, parsing each day once.
  def fetcher
    lambda do |house, date|
      key = "#{house}-#{date}"
      return @documents[key] if @documents.key?(key)

      text = raw(house, date)
      @documents[key] = text && Nokogiri::XML(text)
    end
  end

  # What a snapshot records for one division: the route, and what Stage 1 found by rule that the
  # route and the draft depend on.
  def self.snapshot_row(division, packet)
    routing = packet.routing
    {
      id: division.id, house: division.house, date: division.date.to_s, number: division.number,
      template_id: routing&.template_id, allowed: routing&.allowed_templates, forbidden: routing&.forbidden_templates,
      mode: routing&.mode.to_s, rule: routing&.rule_name, source: packet.source.to_s,
      question: packet.speaker_question.to_s[0, 160], by_reference: packet.question_by_reference?,
      states_motion: packet.question_states_motion?, mover: packet.mover&.member&.name,
      mover_found_by: packet.mover&.found_by&.to_s, motion_found: packet.motion_found?,
      limitation: packet.limitation_statement.present?, warnings: packet.context_warnings.size,
      circulated_by: packet.circulation&.by, circulator_member: packet.circulation&.member&.name
    }
  end
end
