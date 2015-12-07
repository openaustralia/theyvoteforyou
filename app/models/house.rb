class House
  class << self
    def australian
      %w(representatives senate)
    end

    def ukrainian
      "rada"
    end

    def valid?(name)
      if I18n.locale == :uk
        name == ukrainian
      else
        australian.include?(name)
      end
    end
  end
end
