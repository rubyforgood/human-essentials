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
      flash[:error] = @organization.errors.full_messages.join("\n")
      render :edit
    end
  end

  def invite_user
    UserInviteService.invite(email: params[:email],
      name: params[:name],
      roles: [Role::ORG_USER],
      resource: Organization.find(params[:org]))
    redirect_to organization_path, notice: "User invited to organization!"
  rescue => e
    redirect_to organization_path, alert: e.message
  end

  def resend_user_invitation
    user = User.find(params[:user_id])
    user.invite!
    redirect_to organization_path, notice: "User re-invited to organization!"
  end

  def promote_to_org_admin
    user = User.find(params[:user_id])
    raise ActiveRecord::RecordNotFound unless user.has_role?(Role::ORG_USER, current_organization)
    begin
      AddRoleService.call(user_id: user.id,
        resource_type: Role::ORG_ADMIN,
        resource_id: current_organization.id)
      redirect_to user_update_redirect_path, notice: "User has been promoted!"
    rescue => e
      redirect_back(fallback_location: organization_path(current_organization), alert: e.message)
    end
  end

  def demote_to_user
    user = User.find(params[:user_id])
    raise ActiveRecord::RecordNotFound unless user.has_role?(Role::ORG_ADMIN, current_organization)
    begin
      RemoveRoleService.call(user_id: params[:user_id],
        resource_type: Role::ORG_ADMIN,
        resource_id: current_organization.id)
      redirect_to user_update_redirect_path, notice: notice
    rescue => e
      redirect_back(fallback_location: organization_path(current_organization), alert: e.message)
    end
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
    request_type_formatter(params)

    params.require(:organization).permit(
      :name, :short_name, :street, :city, :state,
      :zipcode, :email, :url, :logo, :intake_location,
      :default_storage_location, :default_email_text,
      :invitation_text, :reminder_day, :deadline_day,
      :repackage_essentials, :distribute_monthly,
      :ndbn_member_id, :enable_child_based_requests,
      :enable_individual_requests, :enable_quantity_based_requests,
      :ytd_on_distribution_printout, :one_step_partner_invite,
      partner_form_fields: []
    )
  end

  def request_type_formatter(params)
    if params[:organization][:enable_individual_requests] == "false"
      params[:organization][:enable_child_based_requests] = false
    end

    if params[:organization][:enable_child_based_requests] == "false"
      params[:organization][:enable_individual_requests] = false
    end

    if params[:organization][:enable_quantity_based_requests] == "false"
      params[:organization][:enable_quantity_based_requests] = false
    end

    params
  end

  def user_update_redirect_path
    if current_user.has_role?(Role::SUPER_ADMIN)
      admin_organization_path(current_organization.id)
    else
      organization_path
    end
  end
end
