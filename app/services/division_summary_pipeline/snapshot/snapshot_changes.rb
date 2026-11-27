# frozen_string_literal: true

require "open3"
require "yaml"

module DivisionSummaryPipeline
  # An optional tally of what changed in one year's routing snapshot file
  # (rake ai:route_snapshot_changes): the version on disk against the version saved in git. `git diff`
  # shows every change itself; this counts them, by field and by routing decision, with the divisions
  # under each, for explaining each group of changes in the pull request that made them.
  class SnapshotChanges
    # The file on disk, and its version in git at `against` (a save, branch or tag).
    def self.for(path, against: "HEAD", root: Rails.root)
      path = Pathname(path)
      saved, _error, status = Open3.capture3("git", "show", "#{against}:#{path.relative_path_from(root)}",
                                             chdir: root.to_s)
      new(status.success? ? saved : nil, path.exist? ? path.read : nil)
    end

    # Days in both lists whose Hansard fingerprint differs, as "senate/2026-09-17 (proof, now final)".
    def self.hansard_changes(before, now)
      now.filter_map do |day, about|
        was = before[day]
        next if was.nil? || was["fingerprint"] == about["fingerprint"]

        version = was["version"] == about["version"] ? about["version"] : "#{was['version']}, now #{about['version']}"
        "#{day} (#{version})"
      end
    end

    def initialize(saved_text, current_text)
      @saved = saved_text && YAML.safe_load(saved_text, permitted_classes: [Date])
      @current = current_text && YAML.safe_load(current_text, permitted_classes: [Date])
    end

    # A heading line and a bullet for each group, ready to paste into a pull request.
    def summary(year, against: "HEAD")
      return "#{year}: no file yet. Run rake ai:route_snapshot first." unless current
      return "#{year}: no saved version in #{against} to compare with." unless saved

      heading = "#{year}: #{changed.size} of #{count(after.size, 'division')} changed, compared with #{against}"
      [heading, *added_and_removed, *fields, *routes, *hansard].join("\n")
    end

    private

    attr_reader :saved, :current

    def before
      @before ||= saved.fetch("divisions", nil) || {}
    end

    def after
      @after ||= current.fetch("divisions", nil) || {}
    end

    def changed
      @changed ||= (before.keys & after.keys).reject { |key| before[key] == after[key] }
    end

    def added_and_removed
      { "Added" => after.keys - before.keys, "Removed" => before.keys - after.keys }
        .filter_map { |label, keys| "- #{label} #{keys.size}: #{keys.join(', ')}" if keys.any? }
    end

    # Each field that changed, as "mover.name", with the divisions it changed in.
    def fields
      tally = Hash.new { |hash, field| hash[field] = [] }
      changed.each do |key|
        was = flatten(before[key])
        now = flatten(after[key])
        (was.keys | now.keys).each { |field| tally[field] << key if was[field] != now[field] }
      end
      tally.sort.map { |field, keys| "- #{field} changed in #{keys.size}: #{keys.join(', ')}" }
    end

    # Each move from one routing decision to another, with the divisions that made it.
    def routes
      moves = changed.group_by { |key| [route(before[key]), route(after[key])] }
                     .reject { |(was, now), _keys| was == now }
      moves.map { |(was, now), keys| "- Routing #{was} became #{now} in #{keys.size}: #{keys.join(', ')}" }
    end

    def hansard
      days = self.class.hansard_changes(saved.fetch("hansard_days", nil) || {},
                                        current.fetch("hansard_days", nil) || {})
      days.any? ? ["- Hansard changed for #{count(days.size, 'day')}: #{days.join(', ')}"] : []
    end

    # A block's fields one level down ("route.template"), so a change names the part that moved.
    def flatten(block)
      block.flat_map do |field, value|
        value.is_a?(Hash) ? value.map { |part, inner| ["#{field}.#{part}", inner] } : [[field, value]]
      end.to_h
    end

    def route(block)
      routing = block["route"]
      return "error" unless routing

      "#{routing['mode']} #{routing['template'] || Array(routing['allowed']).join(', ')} (#{routing['rule']})"
    end

    def count(number, word)
      "#{number} #{word.pluralize(number)}"
    end
  end
end
