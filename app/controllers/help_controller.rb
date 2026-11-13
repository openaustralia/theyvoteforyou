# frozen_string_literal: true

class HelpController < ApplicationController
  def faq; end

  def data; end

  def research; end

  def licencing; end

  def style_guide; end

  # Hidden until the ai_disclosure flag is on, as the wording is still to be agreed (issue #1854)
  def ai
    render "home/error404", status: :not_found unless ai_disclosure_enabled?
  end
end
