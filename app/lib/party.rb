# frozen_string_literal: true

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
    %w[XB Other None SPK CWM DCWM PRES DPRES].include?(name) ||
      name[0..2] == "Ind"
  end

  def subject_to_whip?
    !whipless?
  end
end
