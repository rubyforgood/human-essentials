class ManufacturersController < ApplicationController
  def index
    @manufacturers = current_organization.manufacturers.includes(:donations).all.alphabetized
  end

  def create
    @manufacturer = current_organization.manufacturers.new(manufacturer_params.merge(organization: current_organization))
    respond_to do |format|
      if @manufacturer.save
        format.html { redirect_to manufacturers_path, notice: "New Manufacturer added!" }
        format.js
      else
        flash[:error] = "Something didn't work quite right -- try again?"
        format.html { render action: :new }
        format.js { render template: "manufacturers/new_modal" }
      end
    end
  end

  def new
    @manufacturer = current_organization.manufacturers.new
    if request.xhr?
      respond_to do |format|
        format.js { render template: "manufacturers/new_modal" }
      end
    end
  end

  def edit
    @manufacturer = current_organization.manufacturers.find(params[:id])
  end

  def show
    @manufacturer = current_organization.manufacturers.includes(:donations).find(params[:id])
  end

  def update
    @manufacturer = current_organization.manufacturers.find(params[:id])
    if @manufacturer.update(manufacturer_params)
      redirect_to manufacturers_path, notice: "#{@manufacturer.name} updated!"

    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  private

  def manufacturer_params
    params.require(:manufacturer)
          .permit(:name)
  end
end
