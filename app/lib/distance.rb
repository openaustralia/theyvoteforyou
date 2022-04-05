# frozen_string_literal: true

class Distance
  # What this means is that 5 absent votes is as important as one aye or no vote
  ABSENT_FACTOR = 5

  STRONG_FACTOR = 5

  def initialize(same: 0, samestrong: 0, differ: 0, differstrong: 0, absent: 0, absentstrong: 0)
    @votes = {
      same: same,
      samestrong: samestrong,
      differ: differ,
      differstrong: differstrong,
      absent: absent,
      absentstrong: absentstrong
    }
  end

  def no_votes(type)
    @votes[type]
  end

  def types
    @votes.keys
  end

  def distance
    1 - agreement
  end

  # Weights are picked to ensure they have the properties we want and that the
  # points are the smallest they can be while still all being integers
  def self.weights(type)
    case type
    when :same, :differ
      # Regular votes are weighted STRONG_FACTOR less than strong votes
      ABSENT_FACTOR
    when :absent
      # With the exception of regular absent votes which are weighted less
      # again by a factor of ABSENT_FACTOR
      1
    when :samestrong, :differstrong, :absentstrong
      # Strong votes are weighted the same but are more important by
      # a factor of STRONG_FACTOR than regular votes
      STRONG_FACTOR * ABSENT_FACTOR
    end
  end

  def self.score(type)
    case type
    when :same, :samestrong
      1
    when :differ, :differstrong
      0
    when :absent, :absentstrong
      0.5
    end
  end

  def sum_weighted_scores
    types.sum { |type| no_votes(type) * Distance.score(type) * Distance.weights(type) }
  end

  def sum_weights
    types.sum { |type| no_votes(type) * Distance.weights(type) }
  end

  def agreement
    if sum_weights.positive?
      sum_weighted_scores.to_f / sum_weights
    else
      2.0
    end
  end
end
