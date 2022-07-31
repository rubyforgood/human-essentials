# Provides scope-limited access to viewing the data of other users
class UsersController < ApplicationController
  def index
    @users = current_organization.users
  end

  def new
    @user = User.new
  end

  def switch_to_partner_role
    if current_user.partner.nil?
      error_message = "Attempted to switch to a partner role but you have no partner associated with your account!"
      redirect_back(fallback_location: root_path, alert: error_message)
      return
    end

    redirect_to partner_user_root_path
  end
end
