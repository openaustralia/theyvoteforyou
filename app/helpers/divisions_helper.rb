module DivisionsHelper
  def division_date_and_time(division)
    text = formatted_date(division.date)
    text += " at " + division.clock_time.strftime('%H:%M') if division.clock_time
    text
  end

  def division_path2(q, display_active_policy = true, member = false)
    q2 = {
      submit: nil,
      vote1: nil,
      vote2: nil,
      mpn: (member.url_name if  member),
      mpc: (member.electorate if member)
    }
    if q[:dmp]
      q2[:dmp] = q[:dmp]
    elsif display_active_policy && user_signed_in?
      q2[:dmp] = current_user.active_policy_id
    else
      q2[:dmp] = nil
    end
    division_path(q.merge(q2))
  end

  def division_path3(q, display_active_policy = true, member = false)
    q2 = {
      mpn: (member.url_name if member),
      mpc: ((member.australian_house == "senate" ? "Senate" : member.url_electorate) if member)
    }
    if q[:dmp]
      q2[:dmp] = q[:dmp]
    elsif display_active_policy && user_signed_in?
      q2[:dmp] = current_user.active_policy_id
    else
      q2[:dmp] = nil
    end
    division_path(q.merge(q2))
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

  def division_nav_link(display, name, title, current_display)
    params.delete(:house) if params[:house] == 'representatives'
    content_tag(:li, name, class: ("active" if current_display == display)) do
      link_to name, division_path2(params.merge(display: display)), title: title
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
    text.gsub!(/<li>\[(\d+)\]/) { %(<li class="footnote" id="footnote-#{$~[1]}">[#{$~[1]}]) }

    # This is a small hack to make links to an old site point to the new site
    text.gsub!("<a href=\"http://publicwhip-test.openaustraliafoundation.org.au",
      "<a href=\"http://publicwhip-rails.openaustraliafoundation.org.au")
    text
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
