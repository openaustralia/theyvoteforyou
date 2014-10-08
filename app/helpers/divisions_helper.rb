module DivisionsHelper
  def division_date_and_time(division)
    text = formatted_date(division.date)
    text += division.clock_time if division.clock_time
    text
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

  def vote_display_in_table(vote)
    case vote
    when "aye3"
      "Aye (strong)"
    when "no3"
      "No (strong)"
    when "absent"
      "absent"
    when "both"
      "Abstain"
    else
      vote.capitalize
    end
  end

  # TODO: Refactor this - it looks suspiciously like the above
  def simple_vote_display(vote)
    vote == 'aye3' || vote == 'no3' ? "#{vote[0...-1]} (strong)" : vote
  end

  def majority_strength_in_words(division)
    if division.majority_fraction == 1.0
      "unanimously"
    elsif division.majority_fraction == 0.0
      ""
    elsif division.majority_fraction > 2.to_f / 3
      "by a large majority"
    elsif division.majority_fraction > 1.to_f / 3
      "by a moderate majority"
    elsif division.majority_fraction > 0
      "by a small majority"
    end
  end

  def division_outcome_with_majority_strength(division)
    division_outcome(division) + " " + majority_strength_in_words(division)
  end

  def whip_guess_with_strength_in_words(whip)
    if whip.majority_fraction == 1.0
      "unanimously voted " + whip.whip_guess
    elsif whip.majority_fraction == 0.0
      "split"
    elsif whip.majority_fraction > 2.to_f / 3
      "large majority voted " + whip.whip_guess
    elsif whip.majority_fraction > 1.to_f / 3
      "moderate majority voted " + whip.whip_guess
    elsif whip.majority_fraction > 0
      "small majority voted " + whip.whip_guess
    end
  end

  # TODO We should be taking into account the strange rules about tied votes in the Senate
  def division_outcome(division)
    division.passed? ? 'Passed' : 'Not passed'
  end

  def division_outcome_class(division)
    division.passed? ? 'division-outcome-passed' : 'division-outcome-not-passed'
  end

  def division_outcome_with_score(division)
    result = division_outcome(division) + " "
    result += content_tag(:span, class: "division-outcome-score") do
      if division.passed?
        text = division.aye_votes_including_tells.to_s + " – " + division.no_votes_including_tells.to_s
      else
        text = division.no_votes_including_tells.to_s + " – " + division.aye_votes_including_tells.to_s
      end
    end
    result.html_safe
  end

  def member_voted_with(member, division)
    sentence = link_to member.full_name, member
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

  def division_edit_status_class(division)
    if division.edited?
      "division-status-edited"
    else
      "division-status-raw"
    end
  end

  def active_house_for_list_class(house)
    if house == "representatives"
      "display-house-representatives"
    elsif house == "senate"
      "display-house-senate"
    elsif house == nil
      "display-house-all"
    end
  end
end
