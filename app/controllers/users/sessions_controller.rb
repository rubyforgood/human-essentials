# This exists so that we can override some of the devise resource
class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  layout "devise"
  before_action :check_failed_login
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!
  # This one causes a redirect require_no_authentication
  skip_before_action :require_no_authentication

  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    super
    role_order = [Role::SUPER_ADMIN, Role::ORG_ADMIN, Role::ORG_USER, Role::PARTNER]
    session[:current_role] = role_order.find do |role|
      current_user.roles.find { |r| r.name == role }
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def check_failed_login
    @failed_login = (options = request.env["warden.options"]) && options[:action] == "unauthenticated" && options[:message] == :not_found_in_database
  end
end
