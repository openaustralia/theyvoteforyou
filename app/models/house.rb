class House
  class << self
    def uk_to_australian(house)
      case house
      when "commons"
        "representatives"
      when "lords"
        "senate"
      else
        raise "Unexpected value: #{house}"
      end
    end

    def australian_to_uk(australian_house)
      case australian_house
      when "representatives"
        "commons"
      when "senate"
        "lords"
      else
        raise "unexpected value: #{australian_house}"
      end
    end

    def australian
      %w(representatives senate)
    end
  end
end
