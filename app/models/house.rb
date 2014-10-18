class House
  class << self
    def australian_to_uk(house)
      case house
      when 'representatives'
        'commons'
      when 'senate'
        'lords'
      else
        raise "Unknown house #{house}"
      end
    end

    def australian
      %w(representatives senate)
    end
  end
end
