# frozen_string_literal: true

# Where a locally drafted division summary is written, and what the file holds. This is the only
# code that knows the output format, which has to match what the upload in #1815 reads, so a change
# to that format changes only this class. LocalDraftRun writes these files; docs/adr/0007 records
# why they are named this way.
#
#   local_runs/<model id>/<house>/<yyyy-mm-dd>/<house>_<yyyy-mm-dd>_<n>.md
#   local_runs/failed/<model id>/<house>_<yyyy-mm-dd>_<n>.md
#
# The file name is the division's URL path with "_" for "/", so a file names its division wherever
# it ends up; database ids differ between machines. The house and date folders are only there to
# make a folder of thousands of drafts browsable.
class LocalDraftFile
  ROOT = Rails.root.join("local_runs")

  attr_reader :division, :model_id, :root

  def initialize(division, model_id, root: ROOT)
    @division = division
    @model_id = model_id
    @root = Pathname(root)
  end

  def name
    "#{division.house}_#{division.date}_#{division.number}.md"
  end

  def path
    root.join(model_id, division.house, division.date.to_s, name)
  end

  # Failed drafts are kept out of the model's folder, so that folder can be zipped and handed over
  # as it is.
  def failed_path
    root.join("failed", model_id, name)
  end

  def drafted?
    path.exist?
  end

  def failed?
    failed_path.exist?
  end

  # Line 1 is the draft's title as a markdown heading; the rest is its description, which ends with
  # the Reviewer Only section. A failed draft left over from an earlier try is removed.
  def write(result)
    write_atomically(path, "# #{result.title}\n\n#{result.description}\n")
    FileUtils.rm_f(failed_path)
  end

  # Whatever the pipeline managed, with the error first, so a failure can be read without running
  # it again. A draft that failed outright has no title, so the division's own name stands in.
  def write_failed(result)
    title = result.title.presence || division.name
    write_atomically(failed_path, "# #{title}\n\n**Error:** #{result.error}\n\n#{result.description}\n")
  end

  private

  # Written beside the final name and then renamed, so stopping a run mid-write never leaves a
  # half-written draft that a later run would take as done. The name starts with a dot, which the
  # upload ignores, so a draft left half-written by a crash can't be taken for a finished one.
  def write_atomically(target, text)
    FileUtils.mkdir_p(target.dirname)
    partial = target.dirname.join(".#{target.basename}.partial")
    File.write(partial, text)
    File.rename(partial, target)
  end
end
