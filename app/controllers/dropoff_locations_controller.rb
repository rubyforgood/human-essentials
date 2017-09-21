class DropoffLocationsController < ApplicationController
  def index
    @dropoff_locations = current_organization.dropoff_locations.all.order(:name)
  end

  def create
    @dropoff_location = current_organization.dropoff_locations.create(dropoff_location_params)
    redirect_to @dropoff_location, notice: "New dropoff location added!"
  end

  def new
    @dropoff_location = current_organization.dropoff_locations.new
  end

  def edit
    @dropoff_location = current_organization.dropoff_locations.find(params[:id])
  end

  def show
    @dropoff_location = current_organization.dropoff_locations.find(params[:id])
  end

  def update
    @dropoff_location = current_organization.dropoff_locations.find(params[:id])
    @dropoff_location.update_attributes(dropoff_location_params)
    redirect_to @dropoff_location, notice: "#{@dropoff_location.name} updated!"
  end

  def destroy
    current_organization.dropoff_locations.find(params[:id]).destroy
    redirect_to dropoff_locations_path
  end

private
  def dropoff_location_params
    params.require(:dropoff_location).permit(:name, :address)
  end
end
