class ConfirmationsController < Devise::ConfirmationsController
  # Override Devise to automatically sign in the user
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message(:notice, :confirmed) if is_flashing_format?

      # Was this likely an email change or a new sign up?
      if signed_in?(resource_name)
        redirect_to signed_in_root_path(resource)
      else
        sign_in(resource_name, resource)
        redirect_to user_welcome_path
      end
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
    end
  end
end
