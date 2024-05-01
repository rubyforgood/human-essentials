# Provides full CRUD of the Vendor Resource
class VendorsController < ApplicationController
  include Importable

  def index
    @vendors = current_organization.vendors.includes(:purchases).all.alphabetized

    respond_to do |format|
      format.html
      format.csv { send_data Vendor.generate_csv(@vendors), filename: "Vendors-#{Time.zone.today}.csv" }
    end
  end

  def create
    @vendor = current_organization.vendors.new(vendor_params.merge(organization: current_organization))
    respond_to do |format|
      if @vendor.save
        format.html { redirect_to vendors_path, notice: "New vendor added!" }
        format.js
      else
        flash[:error] = "Something didn't work quite right -- try again?"
        format.html { render action: :new }
        format.js { render template: "vendors/new_modal" }
      end
    end
  end

  def new
    @vendor = current_organization.vendors.new
    if request.xhr?
      respond_to do |format|
        format.js { render template: "vendors/new_modal" }
      end
    end
  end

  def edit
    @vendor = current_organization.vendors.find(params[:id])
  end

  def show
    @vendor = current_organization.vendors.includes(:purchases).find(params[:id])
  end

  def update
    @vendor = current_organization.vendors.find(params[:id])
    if @vendor.update(vendor_params)
      redirect_to vendors_path, notice: "#{@vendor.contact_name} updated!"

    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  private

  def vendor_params
    params.require(:vendor)
          .permit(:contact_name, :phone, :email, :business_name, :address)
  end

  helper_method \
    def filter_params
    {}
  end
end
