# frozen_string_literal: true

module DivisionsHelper
  def division_date_and_time(division)
    text = formatted_date(division.date)
    text += ", #{division.clock_time}" if division.clock_time
    text
  end

  def aye_vote_class(whip)
    if whip.aye_votes.zero?
      "normal"
    # Special case for free votes
    elsif whip.whip_guess == "aye" || whip.free?
      "whip"
    else
      "rebel"
    end
  end

  def no_vote_class(whip)
    if whip.no_votes.zero?
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

  def vote_display(vote)
    case vote
    when "aye3"
      "Yes (strong)"
    when "no3"
      "No (strong)"
    when "absent"
      "absent"
    when "both"
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
    vote_class = "voted-#{PolicyDivision.vote_without_strong(vote)}"
    classes = "#{pattern_class} #{vote_class}"

    content_tag(:span, text, class: classes)
  end

  def majority_strength_in_words(division)
    if division.unanimous?
      "unanimously"
    elsif division.tied?
      ""
    else
      out = []
      out << "by a "
      out << content_tag(:span, { class: "has-tooltip", title: division_score(division) }) do
        if division.majority_fraction > 2.to_f / 3
          "large majority"
        elsif division.majority_fraction > 1.to_f / 3
          "modest majority"
        elsif division.majority_fraction.positive?
          "small majority"
        end
      end
      safe_join(out)
    end
  end

  def division_outcome_with_majority_strength(division)
    out = []
    out << division_outcome(division)
    out << " "
    out << majority_strength_in_words(division)
    safe_join(out)
  end

  # TODO: We should be taking into account the strange rules about tied votes in the Senate
  def division_outcome(division)
    division.passed? ? "Passed" : "Not passed"
  end

  def division_outcome_class(division)
    division.passed? ? "division-outcome-passed" : "division-outcome-not-passed"
  end

  def division_score(division)
    if division.passed?
      "#{division.aye_votes_including_tells} #{vote_display 'aye'} – #{division.no_votes_including_tells} #{vote_display 'no'}"
    else
      "#{division.no_votes_including_tells} #{vote_display 'no'} – #{division.aye_votes_including_tells} #{vote_display 'aye'}"
    end
  end

  def member_vote(member, division)
    member.name + " voted #{vote_display(division.vote_for(member))}"
  end

  def member_vote_with_type(member, division)
    sentence = member.name
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
    elsif house.nil?
      "display-house-all"
    end
  end

  def vote_select(form, value, options = {})
    select_options = [
      ["A less important vote", [
        [vote_display("aye"), "aye"],
        [vote_display("no"), "no"]
      ]],
      ["An important vote", [
        [vote_display("aye3"), "aye3"],
        [vote_display("no3"), "no3"]
      ]]
    ]
    form.select :vote, grouped_options_for_select(select_options, value), options, size: 1, class: "selectpicker"
  end

  def divisions_short_description(division)
    "Australian #{division.full_house_name} vote " \
      "#{division_outcome(division).downcase}, #{division_date_and_time(division)}"
  end

  def divisions_period(date_range, date_start)
    case date_range
    when :year
      date_start.year.to_s
    when :month
      formatted_month(date_start)
    when :day
      formatted_date(date_start)
    else
      raise ArgumentError, "Not valid date"
    end
  end

  def rebellion?(vote, whip)
    !whip.free? && vote.vote != whip.whip_guess
  end

  def member_row_class(vote, whip)
    classes = []
    classes << "collapse party-member-row" unless whip.whipless? || whip.possible_votes == 1
    classes << "rebel" if rebellion?(vote, whip)
    classes << "member-row-#{whip.party.parameterize}"
  end
end
