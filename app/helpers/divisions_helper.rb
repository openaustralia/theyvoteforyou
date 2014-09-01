module DivisionsHelper
  def division_date_and_time(division)
    text = formatted_date(division.date)
    text += " at " + division.clock_time.strftime('%H:%M') if division.clock_time
    text
  end

  def division_with_member_path(division, member)
    division_path2(division, {mpn: member.url_name, mpc: member.url_electorate})
  end

  def division_with_policy_path(division, q = {})
    if q[:dmp].nil? && current_user
      division_path2(division, q.merge(dmp: current_user.active_policy_id))
    else
      division_path2(division, q)
    end
  end

  def division_path2(division, q = {})
    division_path(q.merge({
        date: division.date,
        number: division.number,
        house: division.australian_house
      }))
  end

  def aye_vote_class(whip)
    if whip.aye_votes == 0
      "normal"
    # Special case for free votes
    elsif whip.whip_guess == "aye" || whip.free?
      "whip"
    else
      "rebel"
    end
  end

  def no_vote_class(whip)
    if whip.no_votes == 0
      "normal"
    # Special case for free votes
    elsif whip.whip_guess == "no" || whip.free?
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

  def division_nav_link(division, display, name, title, current_display)
    # TODO Don't refer to params in a helper
    content_tag(:li, name, class: ("active" if current_display == display)) do
      link_to name, division_with_policy_path(division, display: display, sort: params[:sort], dmp: params[:dmp]), title: title
    end
  end

  def vote_display_in_table(vote)
    case vote
    when "aye3"
      "Aye (strong)"
    when "no3"
      "No (strong)"
    when "absent"
      "absent"
    else
      vote.capitalize
    end
  end

  # TODO: Refactor this - it looks suspiciously like the above
  def simple_vote_display(vote)
    vote == 'aye3' || vote == 'no3' ? "#{vote[0...-1]} (strong)" : vote
  end

  def member_voted_with(member, division)
    # We're using a different member for the link to try to make things the same as the php
    # TODO get rid of this silliness as soon as we can
    member2 = Member.where(person_id: member.person_id, house: division.house).current_on(division.date).first
    sentence = link_to member2.full_name, member_path(member2)
    sentence += " "
    if member.vote_on_division_without_tell(division) == "absent"
      sentence += "did not vote."
    end

    if !division.action_text.empty? && division.action_text[member.vote_on_division_without_tell(division)]
      sentence += "voted ".html_safe + content_tag(:em, division.action_text[member.vote_on_division_without_tell(division)])
    else
      # TODO Should be using whip for this calculation. Only doing it this way to match php
      # calculation
      ayenodiff = (division.votes.group(:vote).count["aye"] || 0) - (division.votes.group(:vote).count["no"] || 0)
      if ayenodiff == 0
        if member.vote_on_division_without_tell(division) != "absent"
          sentence += "voted #{member.vote_on_division_without_tell(division).capitalize}."
        end
      elsif member.vote_on_division_without_tell(division) == "aye" && ayenodiff >= 0 || member.vote_on_division_without_tell(division) == "no" && ayenodiff < 0
        sentence += "voted ".html_safe + content_tag(:em, "with the majority")
      elsif member.vote_on_division_without_tell(division) != "absent"
        sentence += "voted ".html_safe + content_tag(:em, "in the minority")
      end

      if member.vote_on_division_without_tell(division) != "absent" && ayenodiff != 0
        sentence += " (#{member.vote_on_division_without_tell(division).capitalize})."
      end
      sentence
    end
  end

  def relative_time(time)
    time < 1.month.ago ? formatted_date(time) : "#{time_ago_in_words(time)} ago"
  end
end
