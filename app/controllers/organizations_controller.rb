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
    if @organization.update(organization_params)
      redirect_to organization_path(@organization), notice: "Updated your organization!"
    else
      flash[:error] = "Failed to update your organization."
      render :edit
    end
  end

  def invite_user
    User.invite!(email: params[:email], name: params[:name], organization_id: params[:org])
    redirect_to organization_path, notice: "User invited to organization!"
  end

  def resend_user_invitation
    user = User.find(params[:user_id])
    user.invite!
    redirect_to organization_path, notice: "User re-invited to organization!"
  end

  def promote_to_org_admin
    user = User.find_by!(id: params[:user_id], organization_id: current_organization.id)
    user.update(organization_admin: true)
    redirect_to organization_path, notice: "User has been promoted!"
  end

  def demote_to_user
    user = User.find_by!(id: params[:user_id], organization_id: current_organization.id)
    if user.super_admin?
      notice = "Unable to convert super to user."
    else
      user.update(organization_admin: false)
      notice = "Admin has been changed to User!"
    end

    redirect_to organization_path, notice: notice
  end

  def deactivate_user
    user = User.with_discarded.find_by!(id: params[:user_id], organization_id: current_organization.id)
    user.discard!
    redirect_to organization_path, notice: "User has been deactivated."
  end

  def reactivate_user
    user = User.with_discarded.find_by!(id: params[:user_id], organization_id: current_organization.id)
    user.undiscard!
    redirect_to organization_path, notice: "User has been reactivated."
  end

  private

  def authorize_user
    verboten! unless current_user.super_admin? || (current_organization.id == current_user.organization_id)
  end

  def organization_params
    params.require(:organization).permit(
      :name, :short_name, :street, :city, :state,
      :zipcode, :email, :url, :logo, :intake_location,
      :default_storage_location, :default_email_text,
      :invitation_text, :reminder_day, :deadline_day,
      :repackage_essentials, :distribute_monthly,
      :ndbn_member_id,
      partner_form_fields: []
    )
  end
end
