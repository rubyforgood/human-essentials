class PartnersController < ApplicationController
  def index
    @partners = current_organization.partners
  end

  def create
    @partner = current_organization.partners.create(partner_params)
    redirect_to @partner, notice: "Partner added!"
  end

  def show
    @partner = current_organization.partners.find(params[:id])
  end

  def new
    @partner = current_organization.partners.new
  end

  def edit
    @partner = current_organization.partners.find(params[:id])
  end

  def update
    @partner = current_organization.partners.find(params[:id])
    @partner.update_attributes(partner_params)
    redirect_to @partner, notice: "#{@partner.name} updated!"
  end

  def destroy
    current_organization.partners.find(params[:id]).destroy
    redirect_to partners_path
  end

private
  def partner_params
    params.require(:partner).permit(:name, :email)
  end
end
