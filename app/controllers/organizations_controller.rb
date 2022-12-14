# Provides limited R/W to a scope-limited organization resource (member-routes-only)
class OrganizationsController < ApplicationController
  before_action :authorize_admin, except: [:show]
  before_action :authorize_user, only: [:show]

  def show
    @organization = current_organization
    @header_link = dashboard_path
  end

  def edit
    @organization = current_organization
  end

  def update
    @organization = current_organization
    if OrganizationUpdateService.update(@organization, organization_params)
      redirect_to organization_path(@organization), notice: "Updated your organization!"
    else
      flash[:error] = "Failed to update your organization."
      render :edit
    end
  end

  def invite_user
    UserInviteService.invite(email: params[:email],
      name: params[:name],
      roles: [Role::ORG_USER],
      resource: Organization.find(params[:org]))
    redirect_to organization_path, notice: "User invited to organization!"
  end

  def resend_user_invitation
    user = User.find(params[:user_id])
    user.invite!
    redirect_to organization_path, notice: "User re-invited to organization!"
  end

  def promote_to_org_admin
    user = User.find(params[:user_id])
    raise ActiveRecord::RecordNotFound unless user.has_role?(Role::ORG_USER, current_organization)
    user.add_role(Role::ORG_ADMIN, current_organization)
    redirect_to user_update_redirect_path, notice: "User has been promoted!"
  end

  def demote_to_user
    user = User.find(params[:user_id])
    raise ActiveRecord::RecordNotFound unless user.has_role?(Role::ORG_USER, current_organization)
    if user.has_role?(Role::SUPER_ADMIN)
      notice = "Unable to convert super to user."
    else
      user.remove_role(Role::ORG_ADMIN, current_organization)
      notice = "Admin has been changed to User!"
    end

    redirect_to user_update_redirect_path, notice: notice
  end

  def deactivate_user
    user = User.with_discarded.find_by!(id: params[:user_id])
    raise ActiveRecord::RecordNotFound unless user.has_role?(Role::ORG_USER, current_organization)
    user.discard!
    redirect_to user_update_redirect_path, notice: "User has been deactivated."
  end

  def reactivate_user
    user = User.with_discarded.find_by!(id: params[:user_id])
    raise ActiveRecord::RecordNotFound unless user.has_role?(Role::ORG_USER, current_organization)
    user.undiscard!
    redirect_to user_update_redirect_path, notice: "User has been reactivated."
  end

  private

  def authorize_user
    verboten! unless current_user.has_role?(Role::SUPER_ADMIN) ||
      current_user.has_role?(Role::ORG_USER, current_organization)
  end

  def organization_params
    params.require(:organization).permit(
      :name, :short_name, :street, :city, :state,
      :zipcode, :email, :url, :logo, :intake_location,
      :default_storage_location, :default_email_text,
      :invitation_text, :reminder_day, :deadline_day,
      :repackage_essentials, :distribute_monthly,
      :ndbn_member_id, :enable_child_based_requests,
      :enable_individual_requests, :enable_quantity_based_requests,
      partner_form_fields: []
    )
  end

  def user_update_redirect_path
    if current_user.has_role?(Role::SUPER_ADMIN)
      admin_organization_path(current_organization.id)
    else
      organization_path
    end
  end
end
