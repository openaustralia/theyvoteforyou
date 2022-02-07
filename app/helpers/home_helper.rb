# frozen_string_literal: true

module HomeHelper
  def senator_search(query)
    res = []
    return res unless query.downcase.include?("senator") || query.downcase.include?("senate")

    res << "senate"

    query.downcase.split.each do |string|
      case string
      when "new south wales", "nsw"
        res << "NSW"
      when "victoria", "vic"
        res << "Victoria"
      when "western australia", "wa"
        res << "WA"
      when "queensland", "qld"
        res << "Queensland"
      when "northern territory", "nt"
        res << "NT"
      when "south australia", "sa"
        res << "SA"
      when "tasmania", "tas"
        res << "Tasmania"
      when "canberra", "act"
        res << "ACT"
      end
    end

    res
  end
end
