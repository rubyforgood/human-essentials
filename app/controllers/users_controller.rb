# Provides scope-limited access to viewing the data of other users
class UsersController < ApplicationController
  def index
    @users = current_organization.users
  end

  def new
    @user = User.new
  end

  def switch_to_role
    role = Role.find(params[:role_id])
    session[:current_role] = params[:role_id]
    unless current_user.roles.include?(role)
      error_message = "Attempted to switch to a role that doesn't belong to you!"
      redirect_back(fallback_location: root_path, alert: error_message)
      return
    end

    redirect_to dashboard_path_from_role
  end
end
