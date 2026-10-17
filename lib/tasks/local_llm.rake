# frozen_string_literal: true

# Runs the AI division summary pipeline against a model server on your own machine instead of
# Bedrock (LocalModelClient, set up in config/local_model.yml). Development only: nothing in
# production calls these tasks.
#
# They use the seams the pipeline already has rather than changing it:
# - SemanticExtractor.new(llm_caller:) swaps the Bedrock `converse` call for any callable
#   taking (system_prompt, user_prompt) and returning the model's reply text.
# - DivisionSummarizer.new(models:, extractor:) runs every other stage unchanged.
namespace :ai do
  desc "LOCAL: run the AI division summary pipeline for one division against your own model server " \
       "instead of Bedrock. DIVISION_ID=<id> required; the server is set in config/local_model.yml."
  # Unlike ai:summarize_division this always re-runs and overwrites the saved draft, since the
  # point of a local run is to see the effect of a change.
  task summarize_division_local: :environment do
    division_id = ENV.fetch("DIVISION_ID") { abort "Usage: rake ai:summarize_division_local DIVISION_ID=123" }
    client = LocalModelClient.from_config
    model_id = begin
      client.model_id
    rescue LocalModelClient::Unreachable => e
      abort "#{e.message}. Start it and let it finish loading its model; config/local_model.yml says where it is."
    end

    division = Division.find(division_id)
    extractor = DivisionSummaryPipeline::SemanticExtractor.new(llm_caller: client.llm_caller(division))
    summarizer = DivisionSummarizer.new(division, models: { "local" => model_id }, extractor: extractor)

    puts "Division ##{division.id}: #{division.name}"
    puts "Model: #{model_id} at #{client.url}"
    puts "Every reply is saved under tmp/llm_replies/, with its prompt beside it"
    puts

    summary = AiDivisionSummary.save_from_result!(division, summarizer.summarize_with(model_id))
    if summary.error
      puts "Error: #{summary.error}"
    else
      puts "Title: #{summary.title}"
      puts "Description: #{summary.description}"
    end
  end

  # The way to draft divisions for upload (docs/local-ai-drafts.md): newest first, one file per
  # division under local_runs/, skipping any already drafted so a run can be stopped and restarted.
  desc "LOCAL: draft AI division summaries with your own model server, newest first, into local_runs/ " \
       "for upload. Optional: HOUSE=senate, FROM=2026-08-01, TO=2026-09-30, " \
       "DIVISION=representatives/2026-09-17/3, FORCE=1, RETRY_FAILED=1."
  task draft_local: :environment do
    flag = ->(name) { %w[1 true yes].include?(ENV.fetch(name, "").downcase) }
    date = lambda do |name, default|
      value = ENV.fetch(name, nil).presence
      value ? Date.iso8601(value) : default
    rescue Date::Error
      abort "#{name} must be a date like 2026-09-17"
    end
    house = ENV.fetch("HOUSE", nil).presence
    abort "HOUSE must be #{House.australian.join(' or ')}" if house && House.australian.exclude?(house)

    client = LocalModelClient.from_config
    begin
      puts "Model: #{client.model_id} at #{client.url}"
    rescue LocalModelClient::Unreachable => e
      abort "#{e.message}. Start your model server and let it finish loading its model; " \
            "config/local_model.yml says where it is."
    end

    run = LocalDraftRun.new(client: client, houses: house ? [house] : House.australian,
                            force: flag.call("FORCE"), retry_failed: flag.call("RETRY_FAILED"))
    if (division = ENV.fetch("DIVISION", nil).presence)
      run.run_one(division)
    else
      from = date.call("FROM", LocalDraftRun::EARLIEST)
      to = date.call("TO", Date.current)
      puts "Drafting #{house || 'both houses'} from #{to} back to #{from}. Ctrl-C stops; the same command carries on."
      run.run(from: from, to: to)
    end
  rescue LocalModelClient::Unreachable => e
    abort "\n#{e.message}. Nothing was written for the division it was on. " \
          "Once the server is running with its model loaded, run the same command to carry on."
  rescue LocalDraftRun::EmptyRange, LocalDraftRun::UnknownDivision => e
    abort e.message
  rescue Interrupt
    abort "\nStopped. Run the same command to carry on where it left off."
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
    model_id = LocalModelClient.model_id_for(replies.first["model"])
    answers = replies.map { |reply| LocalModelClient.answer_text(reply) }
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
