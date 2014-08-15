class Distance
  # absents have low weighting, except where it is a strong vote
  STRONG_WEIGHT = 50
  ABSENT_WEIGHT = 2

  attr_reader :same, :samestrong, :differ, :differstrong, :absent, :absentstrong

  def initialize(same, samestrong, differ, differstrong, absent, absentstrong)
    @same, @samestrong, @differ, @differstrong, @absent, @absentstrong =
      same, samestrong, differ, differstrong, absent, absentstrong
  end

  def distance
    1 - agreement
  end

  #####

  def points
    {
      same:         10,
      differ:       0,
      absent:       ABSENT_WEIGHT / 2,
      samestrong:   STRONG_WEIGHT,
      differstrong: 0,
      absentstrong: STRONG_WEIGHT / 2
    }
  end

  def possible_points
    {
      same:         10,
      differ:       10,
      absent:       ABSENT_WEIGHT,
      samestrong:   STRONG_WEIGHT,
      differstrong: STRONG_WEIGHT,
      absentstrong: STRONG_WEIGHT
    }
  end

  def votes_same_points
    same * points[:same]
  end

  def votes_differ_points
    differ * points[:differ]
  end

  def votes_absent_points
    absent * points[:absent]
  end

  def votes_same_strong_points
    samestrong * points[:samestrong]
  end

  def votes_differ_strong_points
    differstrong * points[:differstrong]
  end

  def votes_absent_strong_points
    absentstrong * points[:absentstrong]
  end

  def possible_same_points
    same * possible_points[:same]
  end

  def possible_differ_points
    differ * possible_points[:differ]
  end

  def possible_absent_points
    absent * possible_points[:absent]
  end

  def possible_same_strong_points
    samestrong * possible_points[:samestrong]
  end

  def possible_differ_strong_points
    differstrong * possible_points[:differstrong]
  end

  def possible_absent_strong_points
    absentstrong * possible_points[:absentstrong]
  end

  ####

  def total_points
    votes_same_points + votes_same_strong_points +
      votes_differ_points + votes_differ_strong_points +
      votes_absent_points + votes_absent_strong_points
  end

  def possible_total_points
    possible_same_points + possible_same_strong_points +
      possible_differ_points + possible_differ_strong_points +
      possible_absent_points + possible_absent_strong_points
  end

  # TODO: Need to make this formula more clear
  def agreement
    if possible_total_points > 0
      total_points.to_f / possible_total_points
    else
      2.0
    end
  end

  def self.calculate(same, samestrong, differ, differstrong, absent, absentstrong)
    Distance.new(same, samestrong, differ, differstrong, absent, absentstrong).distance
  end
end
