# frozen_string_literal: true

class Partners::SessionsController < Devise::SessionsController
  layout 'devise_partner_users'
  before_action :configure_sign_in_params, only: [:create]

  skip_before_action :authorize_user
  skip_before_action :authenticate_user!
  # This one causes a redirect require_no_authentication
  skip_before_action :require_no_authentication

  # GET /resource/sign_in
  # def new
  # super
  # end

  # POST /resource/sign_in
  def create
    super
  end

  # DELETE /resource/sign_out
  # def destroy
  # super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  end

  private

  def redirect_to_root
    redirect_to root_path
  end
end
