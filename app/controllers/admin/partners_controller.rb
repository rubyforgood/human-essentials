class Admin::PartnersController < AdminController
  def index
    @partners = Partner.all.includes(:organization)
  end

  def show
    @partner = Partner.find(params[:id])
  end

  def edit
    @partner = Partner.find(params[:id])
  end

  def update
    @partner = Partner.find(params[:id])
    if @partner.update(partner_attributes)
      redirect_to admin_partners_path, notice: "#{@partner.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  private

  def partner_attributes
    params.require(:partner).permit(:name, :email)
  end
end
