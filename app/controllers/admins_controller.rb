class AdminsController < ApplicationController
  before_action :authorize_user

  def edit
    @organization = Organization.find(params[:id])
  end

  def update
    @organization = Organization.find(params[:id])

    if @organization.update_attributes(organization_params)
      redirect_to admins_path, notice: 'Updated organization!'
    else
      flash[:alert] = 'Failed to update this organization.'
      render :edit
    end
  end

  def index
    @organizations = Organization.all
  end

  def invite_user
    User.invite!(email: params[:email], name: params[:name], organization_id: params[:org])
    redirect_to admins_path, notice: 'User invited to organization!'
  end

  # TODO: who should be able to arrive here and how?
  def new
    @organization = Organization.new
  end

  # TODO: who should be able to arrive here and how?

  def create
    @organization = Organization.create(organization_params)
    if @organization.save
      redirect_to admins_path, notice: "Organization added!"
    else
      flash[:alert] = "Failed to create Organization."
      render :new
    end
  end

  def show
    @organization = Organization.find(params[:id])
  end

  private

  def authorize_user
    verboten! unless current_user.organization_admin
  end

  def organization_params
    params.require(:organization).permit(:name, :short_name, :address, :email, :url, :logo)
  end
end
