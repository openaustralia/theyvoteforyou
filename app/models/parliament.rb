# frozen_string_literal: true

# TODO: Store this in the database
class Parliament
  class << self
    def all
      {
        "2013" => { from: Date.new(2013, 11, 12), to: Date.new(9999, 12, 31), name: "2013 (current)" },
        "2010" => { from: Date.new(2010, 9, 28),  to: Date.new(2013, 8, 0o5), name: "2010-2013" },
        "2007" => { from: Date.new(2008, 2, 12),  to: Date.new(2010, 7, 19),  name: "2008-2010" },
        "2004" => { from: Date.new(2004, 11, 16), to: Date.new(2007, 10, 17), name: "2004-2007" }
      }
    end

    # Returns the index (e.g. "2010") of the latest parliament
    def latest
      all.max { |p, q| p[1][:to] <=> q[1][:to] }.first
    end

    def at_date(date)
      # TODO: This range calculation isn't quite right. Fix it
      all.select { |_k, v| date >= v[:from] && date <= v[:to] }.shift
    end
  end
end
