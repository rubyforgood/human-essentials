class DonationSitesController < ApplicationController
  def index
    @donation_sites = current_organization.donation_sites.all.order(:name)
    @donation_site = current_organization.donation_sites.new
  end

  def create
    @donation_site = current_organization.donation_sites.new(donation_site_params)
    respond_to do |format|
      if @donation_site.save
        format.html do
          redirect_to donation_sites_path,
                      notice: "Donation site #{@donation_site.name} added!"
        end
        format.js { render partial: "shared/table_row_prepend", object: @donation_site }
      else
        format.html do
          flash[:error] = "Something didn't work quite right -- try again?"
          render action: :new
        end
        format.js { render partial: "shared/table_row_prepend", object: @partner }
      end
    end
  end

  def new
    @donation_site = current_organization.donation_sites.new
  end

  def edit
    @donation_site = current_organization.donation_sites.find(params[:id])
  end

  def show
    @donation_site = current_organization.donation_sites.find(params[:id])
  end

  def update
    @donation_site = current_organization.donation_sites.find(params[:id])
    if @donation_site.update(donation_site_params)
      redirect_to donation_sites_path, notice: "#{@donation_site.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def import_csv
    if params[:file].nil?
      redirect_back(fallback_location: donation_sites_path(organization_id: current_organization))
      flash[:error] = "No file was attached!"
    else
      filepath = params[:file].read
      DonationSite.import_csv(filepath, current_organization.id)
      flash[:notice] = "Donation sites were imported successfully!"
      redirect_back(fallback_location: donation_sites_path(organization_id: current_organization))
    end
  end

  def destroy
    current_organization.donation_sites.find(params[:id]).destroy
    redirect_to donation_sites_path
  end

  private

  def donation_site_params
    params.require(:donation_site).permit(:name, :address)
  end
end
