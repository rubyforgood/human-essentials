class AdminsController < ApplicationController
  before_action :authorize_user

  def edit
    @current_organization = Organization.find(params[:id])
  end

  def update
    @current_organization = Organization.find(params[:id])

    if @current_organization.update(organization_params)
      redirect_to admins_path, notice: "Updated organization!"
    else
      flash[:error] = "Failed to update this organization."
      render :edit
    end
  end

  def index
    @current_organizations = Organization.all
  end

  def invite_user
    User.invite!(email: params[:email], name: params[:name], organization_id: params[:org])
    redirect_to admins_path, notice: "User invited to organization!"
  end

  # TODO: who should be able to arrive here and how?
  def new
    @current_organization = Organization.new
  end

  # TODO: who should be able to arrive here and how?

  def create
    @current_organization = Organization.create(organization_params)
    if @current_organization.save
      redirect_to admins_path, notice: "Organization added!"
    else
      flash[:error] = "Failed to create Organization."
      render :new
    end
  end

  def show
    @current_organization = Organization.find(params[:id])
  end

  def destroy
    @current_organization = Organization.find(params[:id])
    if @current_organization.destroy
      redirect_to admins_path, notice: "Organization deleted!"
    else
      redirect_to admins_path, alert: "Failed to delete Organization."
    end
  end

  private

  def authorize_user
    verboten! unless current_user.organization_admin
  end

  def organization_params
    params.require(:organization).permit(:name, :short_name, :address, :email, :url, :logo)
  end
end
