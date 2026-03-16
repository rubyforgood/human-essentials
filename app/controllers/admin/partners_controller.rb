class Admin::PartnersController < AdminController
  def index
    @partners = Partner.all.includes(:organization).order("LOWER(name)")
  end

  def show
    @partner = Partner.find(params[:id])
  end

  def edit
    @partner = Partner.find(params[:id])
  end

  def update
    @partner = Partner.find(params[:id])
    partner_update_service = PartnerUpdateService.new(@partner, partner_attributes)
    if partner_update_service.call
      redirect_to admin_partners_path, notice: "#{@partner.name} updated!"
    else
      flash.now[:error] = partner_update_service.error
      render action: :edit
    end
  end

  private

  def partner_attributes
    params.require(:partner).permit(:name, :email)
  end
end
