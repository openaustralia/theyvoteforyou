# frozen_string_literal: true

require "zip"

# Reads a zip of draft division summaries, written elsewhere (for example by a model on a
# volunteer's computer), and saves each as an AiDivisionSummary for a human to review. The layout
# is agreed in https://github.com/openaustralia/theyvoteforyou/issues/1815:
#
#   [model-name]/[house]/[yyyy-mm-dd]/[house]_[yyyy-mm-dd]_[n].md
#
# - The first folder is the model, which is who the draft is attributed to.
# - The file name alone says which division it is. The house and date folders are only for
#   people browsing the zip, so they are not read.
# - Line 1 of a file is the draft's title, as a Markdown heading. The rest is the description.
#
# One bad file fails the whole upload and nothing is saved, so an admin never has half a zip
# applied. Every problem found is reported, not just the first.
#
# Files are read in memory and never written out, so a hostile path inside the zip can't land
# anywhere on disk. Limits are below.
class DivisionSummaryIngest
  Result = Struct.new(:saved, :errors, keyword_init: true)

  FILE_NAME = /\A(?<house>#{House.australian.join('|')})_(?<date>\d{4}-\d{2}-\d{2})_(?<number>\d+)\.md\z/
  MODEL_NAME = /\A[\w.-]+\z/
  MAX_ENTRIES = 5_000
  MAX_FILE_BYTES = 1_000_000

  Draft = Struct.new(:division, :model, :title, :description)

  def initialize(ingest)
    @ingest = ingest
    @errors = []
  end

  def process
    drafts = read_drafts
    @errors << "The zip holds no draft summaries (.md files)" if drafts.empty? && @errors.empty?
    return Result.new(saved: 0, errors: @errors) if @errors.any?

    save(drafts)
    Result.new(saved: drafts.size, errors: [])
  rescue Zip::Error => e
    Result.new(saved: 0, errors: ["Could not read the zip: #{e.message}"])
  end

  private

  def read_drafts
    Zip::File.open(@ingest.file_path) do |zip|
      files = zip.entries.select { |entry| entry.file? && !ignorable?(entry) }
      if files.size > MAX_ENTRIES
        @errors << "The zip holds more than #{MAX_ENTRIES} files"
        return []
      end

      drafts = files.filter_map { |entry| draft_from(entry) }
      duplicate_errors(drafts)
      drafts
    end
  end

  # Zips made on a Mac carry __MACOSX resource files and .DS_Store alongside the real ones.
  def ignorable?(entry)
    entry.name.start_with?("__MACOSX/") || File.basename(entry.name).start_with?(".")
  end

  def draft_from(entry)
    parts = entry.name.split("/")
    return error(entry, "is not inside a model folder") if parts.size < 2

    model = parts.first
    file_name = parts.last
    return error(entry, "has a model folder name with characters other than letters, digits, . _ -") unless MODEL_NAME.match?(model)

    match = FILE_NAME.match(file_name) or return error(entry, "is not named [house]_[yyyy-mm-dd]_[n].md")
    return error(entry, "is larger than #{MAX_FILE_BYTES} bytes") if entry.size > MAX_FILE_BYTES

    division = find_division(match) or return error(entry, "is for a division we don't have")
    title, description = split(entry.get_input_stream.read.to_s.dup.force_encoding(Encoding::UTF_8))
    return error(entry, "has no title on its first line") if title.blank?
    return error(entry, "has no description after its title") if description.blank?

    Draft.new(division, model, title, description)
  end

  def find_division(match)
    Division.find_by(house: match[:house], date: match[:date], number: match[:number])
  rescue Date::Error
    nil
  end

  # Line 1 is the title, usually as a Markdown heading ("# Title"), and the rest is the description.
  def split(text)
    first, rest = text.strip.split("\n", 2)
    [first.to_s.sub(/\A\s*#+\s*/, "").strip, rest.to_s.strip]
  end

  # Two files for the same model and division would silently overwrite each other.
  def duplicate_errors(drafts)
    drafts.group_by { |draft| [draft.model, draft.division.id] }.each_value do |same|
      next if same.one?

      @errors << "#{same.first.model} has more than one draft for #{same.first.division.name} " \
                 "(#{same.first.division.house} #{same.first.division.date} ##{same.first.division.number})"
    end
  end

  # An upload again from the same model replaces its earlier draft for that division, the same
  # way AiDivisionSummary.save_from_result! does.
  def save(drafts)
    AiDivisionSummary.transaction do
      drafts.each do |draft|
        summary = AiDivisionSummary.find_or_initialize_by(division: draft.division, model: draft.model)
        summary.update!(title: draft.title, description: draft.description, ingest: @ingest,
                        raw_response: nil, error: nil, system_prompt: nil, user_prompt: nil)
      end
    end
  end

  def error(entry, problem)
    @errors << "#{entry.name} #{problem}"
    nil
  end
end
