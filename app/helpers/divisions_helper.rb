module DivisionsHelper
  def division_date_and_time(division)
    text = formatted_date(division.date)
    text += " at " + division.clock_time.strftime('%H:%M') if division.clock_time
    text
  end

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

  def division_path(q, display_active_policy = true, member = false)
    p = ""
    p += "&date=#{q[:date]}" if q[:date]
    p += "&number=#{q[:number]}" if q[:number]
    p += "&mpn=#{member.url_name}" if member
    p += "&mpc=#{member.electorate}" if member
    p += "&dmp=#{q[:dmp]}" if q[:dmp] && !(display_active_policy && user_signed_in?)
    p += "&house=#{q[:house]}" if q[:house]
    p += "&display=#{q[:display]}" if q[:display]
    p += "&sort=#{q[:sort]}" if q[:sort]
    p += "&dmp=#{q[:dmp] || current_user.active_policy_id}" if display_active_policy && user_signed_in?
    r = "division.php"
    r += "?" + p[1..-1] if p != ""
    r
  end

  def division_path2(q, display_active_policy = true, member = false)
    p = ""
    p += "&date=#{q[:date]}" if q[:date]
    p += "&number=#{q[:number]}" if q[:number]
    p += "&mpn=#{member.url_name}" if member
    p += "&mpc=#{member.electorate}" if member
    p += "&house=#{q[:house]}" if q[:house]
    p += "&display=#{q[:display]}" if q[:display]
    p += "&sort=#{q[:sort]}" if q[:sort]
    if q[:dmp]
      p += "&dmp=#{q[:dmp]}"
    elsif display_active_policy && user_signed_in?
      p += "&dmp=#{current_user.active_policy_id}"
    end
    r = "division.php"
    r += "?" + p[1..-1] if p != ""
    r
  end

  def division_path3(q, display_active_policy = true, member = false)
    p = ""
    p += "&date=#{q[:date]}" if q[:date]
    p += "&number=#{q[:number]}" if q[:number]
    p += "&mpn=#{member.url_name}" if member
    if member
      if member.australian_house == "senate"
        p += "&mpc=Senate"
      else
        p += "&mpc=#{member.url_electorate}"
      end
    end
    p += "&dmp=#{q[:dmp]}" if q[:dmp] && !(display_active_policy && user_signed_in?)
    p += "&house=#{q[:house]}" if q[:house]
    p += "&display=#{q[:display]}" if q[:display]
    p += "&sort=#{q[:sort]}" if q[:sort]
    p += "&dmp=#{q[:dmp] || current_user.active_policy_id}" if display_active_policy && user_signed_in?
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

  def sort_link_division(sort, name, current_sort)
    if current_sort == sort
      content_tag(:b, name)
    else
      link_to name, division_path(params.merge(sort: sort, dmp: nil), false)
    end
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
    params.delete(:house) if params[:house] == 'representatives'
    content_tag(:li, name, class: ("active" if current_display == display)) do
      link_to name, division_path2(params.merge(display: display)), title: title
    end
  end

  def vote_display_in_table(vote, aye_majority)
    display = if (aye_majority >= 0 && (vote == 'aye' || vote == 'aye3')) ||
       (aye_majority <= 0 && (vote == 'no' || vote == 'no3'))
      'Majority'
    elsif vote == 'absent'
      vote
    else
      content_tag(:i, 'minority')
    end

    vote == 'aye3' || vote == 'no3' ? "#{display} (strong)".html_safe : display
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
      # AND THIS IS WRONG FURTHER BECAUSE THE MAJORITY CALCULATION DOESN"T TAKE INTO ACCOUNT THE TELLS
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

  def formatted_motion_text(division)
    text = division.motion

    # Don't wiki-parse large amounts of text as it can blow out CPU/memory.
    # It's probably not edited and formatted in wiki markup anyway. Maximum
    # field size is 65,535 characters. 15,000 characters is more than 12 pages,
    # i.e. more than enough.
    text = text.size > 15000 ? wikimarkup_parse_basic(text) : wikimarkup_parse(text)

    text.html_safe
  end

  def relative_time(time)
    time < 1.month.ago ? formatted_date(time) : "#{time_ago_in_words(time)} ago"
  end

  private

  # Format according to Public Whip's unique-enough-to-be-annoying markup language.
  # It's *similar* to MediaWiki but not quite. It would be so nice to switch to Markdown.
  def wikimarkup_parse(text)
    text.gsub!(/<p class="italic">(.*)<\/p>/) { "<p><i>#{$~[1]}</i></p>" }
    # Remove any preceeding spaces so wikiparser doesn't format with monospaced font
    text.gsub! /^ */, ''
    # Remove comment lines (those starting with '@')
    text = text.lines.reject { |l| l =~ /(^@.*)/ }.join
    # Italics
    text.gsub!(/''(.*?)''/) { "<em>#{$~[1]}</em>" }
    # Parse as MediaWiki
    text = Marker.parse(text).to_html(nofootnotes: true)
    # Strip unwanted tags and attributes
    text = sanitize_motion(text)

    # BUG: Force object back to String from ActiveSupport::SafeBuffer so the below regexs work properly
    text = String.new(text)

    # Footnote links. The MediaWiki parser would mess these up so we do them after parsing
    text.gsub!(/(?<![<li>\s])(\[(\d+)\])/) { %(<sup class="sup-#{$~[2]}"><a class="sup" href='#footnote-#{$~[2]}' onclick="ClickSup(#{$~[2]}); return false;">#{$~[1]}</a></sup>) }
    # Footnotes
    text.gsub(/<li>\[(\d+)\]/) { %(<li class="footnote" id="footnote-#{$~[1]}">[#{$~[1]}]) }
  end

  # Use this in situations where the text is huge and all we want is it to output something
  # similar to what the php is outputting. So, we do a stripped down version of wikimarkup_parse
  # without the stuff that blows up when the text is huge
  def wikimarkup_parse_basic(text)
    text.gsub!(/<p class="italic">(.*)<\/p>/) { "<p><i>#{$~[1]}</i></p>" }
    sanitize_motion(text)
  end

  def sanitize_motion(text)
    sanitize(text, tags: %w(a b i p ol ul li blockquote br em sup sub dl dt dd), attributes: %w(href class pwmotiontext))
  end
end
