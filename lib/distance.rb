class Distance
  # TODO: Need to make this formula more clear
  def self.calculate(nvotessame, nvotessamestrong, nvotesdiffer, nvotesdifferstrong,
    nvotesabsent, nvotesabsentstrong)
    # absents have low weighting, except where it is a strong vote
    strong_weight = 5.0
    absent_weight = 0.2
    weight = nvotessame + strong_weight * nvotessamestrong + nvotesdiffer + strong_weight * nvotesdifferstrong +
          absent_weight * nvotesabsent + strong_weight * nvotesabsentstrong

    score = nvotesdiffer + strong_weight * nvotesdifferstrong + absent_weight / 2 * nvotesabsent + strong_weight / 2 * nvotesabsentstrong
    if weight > 0
      score / weight
    else
      -1.0
    end
  end
end
