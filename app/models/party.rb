class Party
  attr_accessor :name

  def initialize(params)
    @name = params[:name]
  end

  def long_name
    case name
    when "SPK"
      "Speaker"
    when "CWM"
      "Deputy Speaker"
    when "PRES"
      "President"
    when "DPRES"
      "Deputy President"
    else
      name
    end
  end

  # Does this party not have a whip?
  def whipless?
    name == "XB" ||
    name == "Other" ||
    name[0..2] == "Ind" ||
    name == "None" ||
    name == "SPK" ||
    name == "CWM" ||
    name == "DCWM" ||
    name == "PRES" ||
    name == "DPRES"
  end

  # TODO Inline
  def self.long_name(name)
    Party.new(name: name).long_name
  end

  # TODO Inline
  def self.whipless?(party)
    Party.new(name: name).whipless?
  end
end
