# Provides full CRUD for DonationSites. Donation sites are the locations where people in the community can drop off
# donations.
class DonationSitesController < ApplicationController
  include Importable

  def index
    @donation_sites = current_organization.donation_sites.all.alphabetized
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
      else
        format.html do
          flash[:error] = "Something didn't work quite right -- try again?"
          render action: :new
        end
      end
      format.js { render partial: "shared/table_row_prepend", object: @donation_site }
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

  def destroy
    current_organization.donation_sites.find(params[:id]).destroy
    redirect_to donation_sites_path
  end

  private

  def donation_site_params
    params.require(:donation_site).permit(:name, :address)
  end
end
