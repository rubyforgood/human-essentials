class OrganizationsController < ApplicationController
  before_action :authorize_admin, except: [:show]
  before_action :authorize_user, only: [:show]

  def show
    @organization = current_organization
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

  private

  def authorize_admin
    verboten! unless current_user.super_admin? || (current_user.organization_admin? && current_organization.id == current_user.organization_id)
  end

  def authorize_user
    verboten! unless current_user.super_admin? || (current_organization.id == current_user.organization_id)
  end

  def organization_params
    params.require(:organization).permit(:name, :short_name, :street, :city, :state, :zipcode, :email, :url, :logo, :intake_location, :default_email_text)
  end
end
