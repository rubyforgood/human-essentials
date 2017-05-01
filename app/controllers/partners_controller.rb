class PartnersController < ApplicationController
  def index
    @partners = Partner.all
  end

  def create
    @partner = Partner.create(partner_params)
    redirect_to @partner, notice: "Partner added!"
  end

  def show
    @partner = Partner.find(params[:id])
  end

  def new
    @partner = Partner.new
  end

  def edit
    @partner = Partner.find(params[:id])
  end

  def update
    @partner = Partner.find(params[:id])
    @partner.update_attributes(partner_params)
    redirect_to @partner, notice: "#{@partner.name} updated!"
  end

  def destroy
    Partner.find(params[:id]).destroy
    redirect_to partners_path
  end

private
  def partner_params
    params.require(:partner).permit(:name, :email)
  end
end
