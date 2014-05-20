module DivisionsHelper
  # Rather than using url_for which would be the sensible thing, we're constructing the paths
  # by hand to match the order in the php app
  def divisions_path(q = {})
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

  def division_nav_link(display, name, title, current_display)
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

    vote == 'aye3' || vote == 'no3' ? "#{display} (strong)".html_safe : display
  end

  # TODO: Refactor this - it looks suspiciously like the above
  def simple_vote_display(vote)
    vote == 'aye3' || vote == 'no3' ? "#{vote[0...-1]} (strong)" : vote
  end

  def member_voted_with(member, division)
    sentence = link_to @member.full_name, "mp.php?mpn=#{params[:mpn]}&mpc=#{params[:mpc]}&house=#{@house}"
    sentence += " voted "

    if !division.action_text.empty? && division.action_text[@member.vote_on_division(@division)]
      sentence += content_tag(:em, division.action_text[@member.vote_on_division(@division)])
    else
      # TODO Should be using whip for this calculation. Only doing it this way to match php
      # calculation
      # AND THIS IS WRONG FURTHER BECAUSE THE MAJORITY CALCULATION DOESN"T TAKE INTO ACCOUNT THE TELLS
      ayenodiff = (@division.votes.group(:vote).count["aye"] || 0) - (@division.votes.group(:vote).count["no"] || 0)
      if @member.vote_on_division(@division) == "aye" && ayenodiff >= 0 || @member.vote_on_division(@division) == "no" && ayenodiff < 0
        sentence += content_tag(:em, "with the majority")
      else
        sentence += content_tag(:em, "in the minority")
      end

      sentence += " (#{@member.vote_on_division(@division).capitalize})."
    end
  end

  # Format according to Public Whip's unique-enough-to-be-annoying markup language.
  # It's *similar* to MediaWiki but not quite. It would be so nice to switch to Markdown.
  def formatted_motion_text(division)
    text = division.motion

    # Remove comment lines (those starting with '@')
    text = text.lines.reject { |l| l =~ /(^@.*)/ }.join
    # Italics
    text.gsub!(/''(.*?)''/) { "<em>#{$1}</em>" }
    # Parse as MediaWiki
    text = WikiParser.new(data: text).to_html

    # Footnote links. The MediaWiki parser would mess these up so we do them after parsing
    text.gsub!(/(?<![<li>\s])(\[(\d+)\])/) { %(<sup class="sup-#{$2}"><a class="sup" href='#footnote-#{$2}' onclick="ClickSup(#{$2}); return false;">#{$1}</a></sup>) }
    # Footnotes
    text.gsub!(/<li>\[(\d+)\]/) { %(<li class="footnote" id="footnote-#{$1}">[#{$1}]) }

    text.html_safe
  end

  def relative_time(time)
    time < 1.month.ago ? time.strftime("%-d %b %Y") : "#{time_ago_in_words(time)} ago"
  end
end
