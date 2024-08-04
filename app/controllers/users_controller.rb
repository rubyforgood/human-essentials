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
    unless current_user.roles.include?(role)
      error_message = "Attempted to switch to a role that doesn't belong to you!"
      redirect_back(fallback_location: root_path, alert: error_message)
      return
    end

    @role = role
    UsersRole.set_last_role_for(current_user, role)
    session[:current_role] = params[:role_id]
    redirect_to dashboard_path_from_current_role
  end

  def partner_user_reset_password
    partner = current_organization.partners.find_by(id: params[:partner_id])
    if partner.nil?
      redirect_back(fallback_location: root_path,
        alert: "Could not find partner, or you do not have access to this partner!")
      return
    end

    user = User.with_role(:partner, partner)
      .where("LOWER(email) = ?", params[:email].downcase)
      .first
    if user.nil?
      redirect_back(fallback_location: root_path,
        alert: "Could not find partner user for this partner with email #{params[:email]}!")
      return
    end

    user.send_reset_password_instructions
    redirect_back(fallback_location: root_path, notice: "Password e-mail sent!")
  end
end
