module DivisionsHelper
  def division_date_and_time(division)
    text = formatted_date(division.date)
    text += ", #{division.clock_time}" if division.clock_time
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

  def abstention_vote_class(whip)
    if whip.abstention_votes == 0
      "normal"
    # Special case for free votes
    elsif whip.whip_guess == "abstention" || whip.free?
      "whip"
    else
      "rebel"
    end
  end

  def not_voting_vote_class(whip)
    if whip.not_voting_votes == 0
      "normal"
    # Special case for free votes
    elsif whip.whip_guess == "not voting" || whip.free?
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

  def vote_display(vote)
    case vote
    when "aye3"
      "Yes (strong)"
    when "no3"
      "No (strong)"
    when "absent"
      "absent"
    when "both", "abstention"
      "Abstain"
    when "aye"
      "Yes"
    else
      vote.capitalize
    end
  end

  def policy_vote_display_with_class(vote)
    text = vote_display(vote)
    pattern_class = "division-policy-statement-vote"
    vote_class = ("voted-" + PolicyDivision.vote_without_strong(vote))
    classes = pattern_class + " " + vote_class

    content_tag(:span, text, class: classes )
  end

  def majority_strength_in_words(division)
    if division.majority_fraction == 1.0
      "unanimously"
    elsif division.majority_fraction == 0.0
      ""
    else
      _("by a") + " " + content_tag(:span, {class: 'has-tooltip', title: division_score(division)}) do
        if division.majority_fraction > 2.to_f / 3
          "large majority"
        elsif division.majority_fraction > 1.to_f / 3
          "modest majority"
        elsif division.majority_fraction > 0
          "small majority"
        end
      end
    end
  end

  def division_outcome_with_majority_strength(division)
    "#{division_outcome(division)} #{majority_strength_in_words(division)}".html_safe
  end

  def whip_guess_with_strength_in_words(whip)
    if whip.majority_fraction == 1.0
      "unanimously voted " + whip.whip_guess
    elsif whip.majority_fraction == 0.0
      "split"
    elsif whip.majority_fraction > 2.to_f / 3
      "large majority voted " + whip.whip_guess
    elsif whip.majority_fraction > 1.to_f / 3
      "modest majority voted " + whip.whip_guess
    elsif whip.majority_fraction > 0
      "small majority voted " + whip.whip_guess
    end
  end

  # TODO We should be taking into account the strange rules about tied votes in the Senate
  def division_outcome(division)
    division.passed? ? _('Passed') : _('Not passed')
  end

  def division_outcome_class(division)
    division.passed? ? 'division-outcome-passed' : 'division-outcome-not-passed'
  end

  def division_score(division)
    if division.passed?
      "#{division.aye_votes_including_tells.to_s} #{vote_display "aye"} – #{division.no_votes_including_tells.to_s} #{vote_display "no"}"
    else
      "#{division.no_votes_including_tells.to_s} #{vote_display "no"} – #{division.aye_votes_including_tells.to_s} #{vote_display "aye"}"
    end
  end

  def member_voted_with(member, division)
    sentence = link_to member.name, member
    sentence += " "
    if member.vote_on_division_without_tell(division) == "absent"
      sentence += "did not vote"
    end

    if !division.action_text.empty? && division.action_text[member.vote_on_division_without_tell(division)]
      sentence += "voted ".html_safe + content_tag(:em, division.action_text[member.vote_on_division_without_tell(division)])
    else
      # TODO Should be using whip for this calculation. Only doing it this way to match php
      # calculation
      ayenodiff = (division.votes.group(:vote).count["aye"] || 0) - (division.votes.group(:vote).count["no"] || 0)
      if ayenodiff == 0
        if member.vote_on_division_without_tell(division) != "absent"
          sentence += "voted #{vote_display member.vote_on_division_without_tell(division)}"
        end
      elsif member.vote_on_division_without_tell(division) == "aye" && ayenodiff >= 0 || member.vote_on_division_without_tell(division) == "no" && ayenodiff < 0
        sentence += "voted ".html_safe + content_tag(:em, "with the majority")
      elsif member.vote_on_division_without_tell(division) != "absent"
        sentence += "voted ".html_safe + content_tag(:em, "in the minority")
      end

      if member.vote_on_division_without_tell(division) != "absent" && ayenodiff != 0
        sentence += " (#{vote_display member.vote_on_division_without_tell(division)})"
      end
      sentence
    end
  end

  def member_vote(member, division)
    member.name_without_title + " voted #{vote_display(division.vote_for(member))}"
  end

  def member_vote_with_type(member, division)
    sentence = member.name_without_title
    if member.attended_division?(division)
       sentence += " voted #{vote_display(division.vote_for(member))}"
      if member.division_vote(division).rebellion?
        sentence += ", rebelling against"
        sentence += " the #{member.party_name}"
      elsif division.whip_for_party(member.party).free_vote?
        sentence += " in this free vote"
      end
    else
      sentence += " was absent"
    end
    sentence
  end

  def member_vote_with_party(member, division)
    sentence = member.name_without_title
    if member.attended_division?(division)
      sentence += " voted #{vote_display(division.vote_for(member))}"
      if member.has_whip? && !division.whip_for_party(member.party).free_vote?
        sentence += member.division_vote(division).rebellion? ? " against" : " with"
        sentence += " the #{member.party_name}"
      elsif division.whip_for_party(member.party).free_vote?
        sentence += " in a free vote"
      end
    else
      sentence += " was absent"
    end

    sentence
  end

  def member_vote_class(member, division)
    "member-voted-" + vote_display(division.vote_for(member))
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

  def vote_select(f, value, options = {})
    select_options = [
      ['A less important vote', [
        [vote_display('aye'), 'aye'],
        [vote_display('no'), 'no']
      ]],
      ['An important vote', [
        [vote_display('aye3'), 'aye3'],
        [vote_display('no3'), 'no3']
      ]]
    ]
    f.select :vote, grouped_options_for_select(select_options, value), options, size: 1, class: "selectpicker"
  end

  def divisions_short_description(division)
    "Australian #{division.full_house_name} vote " +
    "#{division_outcome(division).downcase}, #{division_date_and_time(@division)}"
  end

  def divisions_period
    if @year
      @year
    elsif @month
      formatted_month(@month)
    elsif @date
      formatted_date(Date.parse(@date))
    end
  end
end
