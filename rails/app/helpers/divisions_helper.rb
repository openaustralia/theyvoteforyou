module DivisionsHelper
  # Rather than using url_for which would be the sensible thing, we're constructing the paths
  # by hand to match the order in the php app
  def divisions_path(q)
    p = ""
    p += "&rdisplay=#{q[:rdisplay]}" if q[:rdisplay]
    p += "&rdisplay2=#{q[:rdisplay2]}" if q[:rdisplay2]
    p += "&house=#{q[:house]}" if q[:house]
    p += "&sort=#{q[:sort]}" if q[:sort]
    r = "/divisions.php"
    r += "?" + p[1..-1] if p != ""
    r
  end

  def division_path(q)
    p = ""
    p += "&date=#{q[:date]}" if q[:date]
    p += "&number=#{q[:number]}" if q[:number]
    p += "&dmp=#{q[:dmp]}" if q[:dmp]
    p += "&house=#{q[:house]}" if q[:house]
    p += "&display=#{q[:display]}" if q[:display]
    p += "&sort=#{q[:sort]}" if q[:sort]
    r = "division.php"
    r += "?" + p[1..-1] if p != ""
    r
  end

  def sort_link_divisions(sort, sort_name, name, current_sort)
    if current_sort == sort
      content_tag(:b, name)
    else
      link_to name, divisions_path(params.merge(sort: sort)), alt: "Sort by #{sort_name}"
    end
  end

  def majority_vote_class(whip)
    if whip.majority_votes == 0
      "normal"
    # Special case for free votes
    elsif whip.whip_guess_majority == "majority" || whip.free?
      "whip"
    else
      "rebel"
    end
  end

  def minority_vote_class(whip)
    if whip.minority_votes == 0
      "normal"
    elsif whip.whip_guess_majority == "minority" || whip.free?
      "whip"
    else
      "rebel"
    end
  end

  def no_vote_total_class(division)
    division.no_votes >= division.aye_votes ? "whip" : "normal"
  end

  def aye_vote_total_class(division)
    division.aye_votes >= division.no_votes ? "whip" : "normal"
  end

  def majority_vote_total_class(division)
    if division.noes_in_majority?
      division.no_votes >= division.aye_votes ? "whip" : "normal"
    else
      division.aye_votes >= division.no_votes ? "whip" : "normal"
    end
  end

  def minority_vote_total_class(division)
    division.noes_in_majority? ? aye_vote_total_class(division) : no_vote_total_class(division)
  end

  def display_link(display, name, title, current_display)
    if current_display == display
      content_tag(:li, name, class: "on")
    else
      params.delete(:house) if params[:house] == 'representatives'
      content_tag(:li, class: "off") do
        link_to name, division_path(params.merge(display: display)), title: title, class: "off"
      end
    end
  end

  def vote_display_in_table(vote, aye_majority)
    if (aye_majority >= 0 && (vote == 'aye' || vote == 'aye3')) ||
       (aye_majority <= 0 && (vote == 'no' || vote == 'no3'))
      display = 'Majority'
    else
      display = content_tag(:i, 'minority')
    end

    vote == 'aye3' || vote == 'no3' ? "#{display} (strong)" : display
  end

  # TODO: Refactor this - it looks suspiciously like the above
  def simple_vote_display(vote)
    vote == 'aye3' || vote == 'no3' ? "#{vote[0...-1]} (strong)" : vote
  end
end
