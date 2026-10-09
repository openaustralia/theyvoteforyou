# frozen_string_literal: true

# Stops every policy and division subscription a person has, from the address in the List-Unsubscribe header of policy
# update emails. Authorised by a signed token in the address (User#unsubscribe_token), so no login is needed.
#
# A mail client does the one-click POST (RFC 8058) without a form token. A GET, from a mail client without one-click
# support or someone opening the address, only asks for confirmation. It changes nothing, because mail scanners and link
# previews fetch addresses without the person choosing to.
class UnsubscribesController < ApplicationController
  skip_forgery_protection only: :create
  # Otherwise the signed token in the address would be kept in the session as the person's last page
  skip_after_action :store_location
  before_action :keep_out_of_browser_tracking
  before_action :find_user

  def show; end

  def create
    @count = @user.watches.count
    @user.watches.destroy_all
  end

  private

  # The address holds the token, and the browser Sentry and Plausible scripts record the page address. Whoever can read it
  # there could unsubscribe the person.
  def keep_out_of_browser_tracking
    @private_url = true
  end

  def find_user
    @user = User.from_unsubscribe_token(params[:token])
    render :invalid, status: :not_found unless @user
  end
end
