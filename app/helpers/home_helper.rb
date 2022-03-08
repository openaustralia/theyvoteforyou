# frozen_string_literal: true

module HomeHelper
  def house_constituency_from_query(query)
    res = []
    states = {
      nsw: "NSW",
      victoria: "Victoria",
      vic: "Victoria",
      wa: "WA",
      queensland: "Queensland",
      qld: "Queensland",
      nt: "NT",
      sa: "SA",
      tasmania: "Tasmania",
      tas: "Tasmania",
      canberra: "ACT",
      act: "ACT",
      "new south wales": "NSW",
      "western australia": "WA",
      "northern territory": "NT",
      "south australia": "SA"
    }

    return res unless query.downcase.include?("senator") || query.downcase.include?("senate")

    res << "senate"

    states.each_key do |key|
      Rails.logger.debug key
      if query.downcase.include?(key.to_s)
        res << states[key]
        break
      end
    end

    res
  end
end
