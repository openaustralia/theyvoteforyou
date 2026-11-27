# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::SnapshotChanges do
  # A snapshot file's contents, as RouteSnapshot writes them.
  def snapshot(divisions, hansard_days = {})
    YAML.dump({ "hansard_days" => hansard_days, "divisions" => divisions })
  end

  # Fresh hashes each time, as SnapshotRecord builds them: YAML.dump writes an object used twice as
  # an alias, which the snapshot never contains and safe_load refuses.
  def shortlist
    { "route" => { "mode" => "constrained", "template" => nil, "allowed" => [2, 29],
                   "rule" => "SECOND_READING_NUANCE" },
      "mover" => { "name" => "Alex Pemberton", "found_by" => "recent_move" } }
  end

  def settled
    { "route" => { "mode" => "deterministic", "template" => 29, "allowed" => [29],
                   "rule" => "SECOND_READING_QUESTION" },
      "mover" => { "name" => "Daniel Whitfield", "found_by" => "chair_named" } }
  end

  describe "#summary" do
    it "counts each field that changed, with the divisions it changed in" do
      changes = described_class.new(snapshot("senate_2026-09-17_1" => shortlist, "senate_2026-09-17_2" => shortlist),
                                    snapshot("senate_2026-09-17_1" => settled, "senate_2026-09-17_2" => shortlist))

      expect(changes.summary(2026)).to include("2026: 1 of 2 divisions changed, compared with HEAD",
                                               "- mover.name changed in 1: senate_2026-09-17_1",
                                               "- route.template changed in 1: senate_2026-09-17_1")
    end

    it "groups the routing decisions that moved, old to new" do
      changes = described_class.new(snapshot("senate_2026-09-17_1" => shortlist),
                                    snapshot("senate_2026-09-17_1" => settled))

      expect(changes.summary(2026)).to include("- Routing constrained 2, 29 (SECOND_READING_NUANCE) became " \
                                               "deterministic 29 (SECOND_READING_QUESTION) in 1: senate_2026-09-17_1")
    end

    it "lists divisions added and removed" do
      changes = described_class.new(snapshot("senate_2026-09-16_1" => shortlist),
                                    snapshot("senate_2026-09-17_1" => shortlist))

      expect(changes.summary(2026)).to include("- Added 1: senate_2026-09-17_1", "- Removed 1: senate_2026-09-16_1")
    end

    it "names the Hansard days that changed" do
      changes = described_class.new(
        snapshot({}, "senate/2026-09-17" => { "version" => "proof", "fingerprint" => "aaaa" }),
        snapshot({}, "senate/2026-09-17" => { "version" => "final", "fingerprint" => "bbbb" })
      )

      expect(changes.summary(2026)).to include("- Hansard changed for 1 day: senate/2026-09-17 (proof, now final)")
    end

    it "is only the heading when nothing changed" do
      same = snapshot("senate_2026-09-17_1" => shortlist)

      expect(described_class.new(same, same).summary(2026)).to eq("2026: 0 of 1 division changed, compared with HEAD")
    end

    it "says so when there is nothing to compare" do
      expect(described_class.new(nil, snapshot({})).summary(2026))
        .to eq("2026: no saved version in HEAD to compare with.")
      expect(described_class.new(snapshot({}), nil).summary(2026)).to start_with("2026: no file yet.")
    end
  end

  describe ".for" do
    it "compares the file on disk with its version in git" do
      Dir.mktmpdir do |dir|
        file = Pathname(dir).join("2026.yml")
        git = ["git", "-C", dir, "-c", "user.name=Test", "-c", "user.email=test@example.org",
               "-c", "commit.gpgsign=false"]
        file.write(snapshot("senate_2026-09-17_1" => shortlist))
        system(*git, "init", "-q") && system(*git, "add", ".") && system(*git, "commit", "-q", "-m", "Baseline")
        file.write(snapshot("senate_2026-09-17_1" => settled))

        expect(described_class.for(file, root: Pathname(dir)).summary(2026)).to include("1 of 1 division changed")
      end
    end
  end
end
