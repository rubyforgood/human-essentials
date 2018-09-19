class PartnersController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!, :authorize_user, :only => [:review]

  def index
    @partners = current_organization.partners.order(:name)
  end

  def create
    @partner = current_organization.partners.new(partner_params)
    if @partner.save
      redirect_to partners_path, notice: "Partner added!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def review
    test = params["status"]
    @partner = Partner.find(params["partner_id"])
    @partner.update_attributes(status: "Awaiting Review") if test
    render status: 200, json: "Status changed to: #{@partner.status}".to_json
  end

  def approve_partner
    @partner = current_organization.partners.find(params[:partner_id])
  end

  def approve_application
    @partner = current_organization.partners.find(params[:partner_id])
    @partner.update_attributes(status: "Approved")
    DiaperPartnerClient.approve(@partner.attributes)
    redirect_to partners_path
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
    if @partner.update(partner_params)
      redirect_to partners_path, notice: "#{@partner.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def import_csv
    if params[:file].nil?
      redirect_back(fallback_location: partners_path(organization_id: current_organization))
      flash[:error] = "No file was attached!"
    else
      filepath = params[:file].path
      Partner.import_csv(filepath, current_organization.id)
      flash[:notice] = "Partners were imported successfully!"
      redirect_back(fallback_location: partners_path(organization_id: current_organization))
    end
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
