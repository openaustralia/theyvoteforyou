class Distance
  attr_reader :same, :samestrong, :differ, :differstrong, :absent, :absentstrong

  def initialize(same, samestrong, differ, differstrong, absent, absentstrong)
    @same, @samestrong, @differ, @differstrong, @absent, @absentstrong =
      same, samestrong, differ, differstrong, absent, absentstrong
  end

  # TODO: Need to make this formula more clear
  def calculate
    # absents have low weighting, except where it is a strong vote
    strong_weight = 5.0
    absent_weight = 0.2

    score = differ + strong_weight * differstrong + absent_weight / 2 * absent + strong_weight / 2 * absentstrong
    weight = same + strong_weight * samestrong + differ + strong_weight * differstrong +
          absent_weight * absent + strong_weight * absentstrong

    if weight > 0
      score / weight
    else
      -1.0
    end
  end

  def self.calculate(same, samestrong, differ, differstrong, absent, absentstrong)
    Distance.new(same, samestrong, differ, differstrong, absent, absentstrong).calculate
  end
end
