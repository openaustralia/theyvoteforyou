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

  def votes_same_points
    same * 10
  end

  def votes_differ_points
    0
  end

  def votes_absent_points
    absent * ABSENT_WEIGHT / 2
  end

  ###

  def votes_same_strong_points
    samestrong * STRONG_WEIGHT
  end

  def votes_differ_strong_points
    0
  end

  def votes_absent_strong_points
    absentstrong * STRONG_WEIGHT / 2
  end

  def score
    votes_same_points + votes_same_strong_points + votes_absent_points + votes_absent_strong_points
  end

  ####

  def possible_same_points
    same * 10
  end

  def possible_differ_points
    differ * 10
  end

  def possible_absent_points
    absent * ABSENT_WEIGHT
  end

  ####

  def possible_same_strong_points
    samestrong * STRONG_WEIGHT
  end

  def possible_differ_strong_points
    differstrong * STRONG_WEIGHT
  end

  def possible_absent_strong_points
    absentstrong * STRONG_WEIGHT
  end

  ####

  def weight
    possible_same_points + possible_same_strong_points + possible_differ_points + possible_differ_strong_points +
          possible_absent_points + possible_absent_strong_points
  end

  # TODO: Need to make this formula more clear
  def agreement
    if weight > 0
      score.to_f / weight
    else
      2.0
    end
  end

  def self.calculate(same, samestrong, differ, differstrong, absent, absentstrong)
    Distance.new(same, samestrong, differ, differstrong, absent, absentstrong).distance
  end
end
