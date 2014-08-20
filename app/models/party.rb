class Party
  def self.long_name(party)
    case party
    when "SPK"
      "Speaker"
    when "CWM"
      "Deputy Speaker"
    when "PRES"
      "President"
    when "DPRES"
      "Deputy President"
    else
      party
    end
  end

  # Does this party not have a whip?
  def self.whipless?(party)
    party == "XB" ||
    party == "Other" ||
    party[0..2] == "Ind" ||
    party == "None" ||
    party == "SPK" ||
    party == "CWM" ||
    party == "DCWM" ||
    party == "PRES" ||
    party == "DPRES"
  end
end
