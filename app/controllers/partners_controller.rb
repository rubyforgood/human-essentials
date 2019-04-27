class PartnersController < ApplicationController
  include Importable

  def index
    @partners = current_organization.partners.order(:name)
  end

  def create
    @partner = current_organization.partners.new(partner_params)
    if @partner.save
      @partner.register_on_partnerbase
      redirect_to partners_path, notice: "Partner added and invited!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def approve_application
    @partner = current_organization.partners.find(params[:id])
    @partner.approved!
    DiaperPartnerClient.put(@partner.attributes)
    redirect_to partners_path
  end

  def show
    @partner = current_organization.partners.find(params[:id])
  end

  def new
    @partner = current_organization.partners.new
  end

  def approve_partner
    @partner = current_organization.partners.find(params[:id])

    # TODO: create a service that abstracts all of this from PartnersController, like PartnerDetailRetriever.call(id: params[:id])

    # TODO: move this code to new service,
    @diaper_partner = DiaperPartnerClient.get(id: params[:id])
    @diaper_partner = JSON.parse(@diaper_partner, symbolize_names: true) if @diaper_partner
    @agency = if @diaper_partner
                @diaper_partner[:agency]
              else
                autovivifying_hash
              end
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

  def destroy
    current_organization.partners.find(params[:id]).destroy
    redirect_to partners_path
  end

  def invite
    partner = current_organization.partners.find(params[:id])
    partner.register_on_partnerbase
    redirect_to partners_path, notice: "#{partner.name} invited!"
  end

  private

  def autovivifying_hash
    Hash.new { |ht, k| ht[k] = autovivifying_hash }
  end

  def partner_params
    params.require(:partner).permit(:name, :email)
  end
end
