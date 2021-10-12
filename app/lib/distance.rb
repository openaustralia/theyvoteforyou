class Distance
  # What this means is that 5 absent votes is as important as one aye or no vote
  ABSENT_FACTOR = 5

  STRONG_FACTOR = 5

  attr_reader :same, :samestrong, :differ, :differstrong, :absent, :absentstrong

  def initialize(same, samestrong, differ, differstrong, absent, absentstrong)
    @same, @samestrong, @differ, @differstrong, @absent, @absentstrong =
      same, samestrong, differ, differstrong, absent, absentstrong
  end

  def distance
    1 - agreement
  end

  # Weights are picked to ensure they have the properties we want and that the
  # points are the smallest they can be while still all being integers
  def self.weights
    {
      # Regular votes are weighted STRONG_FACTOR less than strong votes
      same:         ABSENT_FACTOR,
      differ:       ABSENT_FACTOR,
      # With the exception of regular absent votes which are weighted less
      # again by a factor of ABSENT_FACTOR
      absent:       1,
      # Strong votes are weighted the same but are more important by
      # a factor of STRONG_FACTOR than regular votes
      samestrong:   STRONG_FACTOR * ABSENT_FACTOR,
      differstrong: STRONG_FACTOR * ABSENT_FACTOR,
      absentstrong: STRONG_FACTOR * ABSENT_FACTOR
    }
  end

  def self.points
    # On a scale between 0 and 2, 0 is voting differently, 1 is when
    # one of two sides is absent and 2 is voting the same.
    {
      same:         2 * weights[:same],
      differ:       0 * weights[:differ],
      absent:       1 * weights[:absent],
      samestrong:   2 * weights[:samestrong],
      differstrong: 0 * weights[:differstrong],
      absentstrong: 1 * weights[:absentstrong]
    }
  end

  def self.possible_points
    # 2 is the maximum we can get but it's all weighted by the same amounts
    # used in self.points above
    {
      same:         2 * weights[:same],
      differ:       2 * weights[:differ],
      absent:       2 * weights[:absent],
      samestrong:   2 * weights[:samestrong],
      differstrong: 2 * weights[:differstrong],
      absentstrong: 2 * weights[:absentstrong]
    }
  end

  def no_votes
    {
      same: same,
      differ: differ,
      absent: absent,
      samestrong: samestrong,
      differstrong: differstrong,
      absentstrong: absentstrong
    }
  end

  def attributes
    no_votes.keys
  end

  def votes_points(a)
    no_votes[a] * Distance.points[a]
  end

  def possible_votes_points(a)
    no_votes[a] * Distance.possible_points[a]
  end

  def total_points
    attributes.sum {|a| votes_points(a) }
  end

  def possible_total_points
    attributes.sum {|a| possible_votes_points(a) }
  end

  def agreement
    if possible_total_points > 0
      total_points.to_f / possible_total_points
    else
      2.0
    end
  end

  def self.distance_a(same, diff, absent, same_strong = 0, diff_strong = 0, absent_strong = 0)
    Distance.new(same, same_strong, diff, diff_strong, absent, absent_strong).distance
  end
end
