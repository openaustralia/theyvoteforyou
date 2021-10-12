class House
  class << self
    def australian
      %w[representatives senate]
    end

    def valid?(name)
      australian.include?(name)
    end
  end
end
