class DropoffLocationsController < ApplicationController
  def index
    @dropoff_locations = DropoffLocation.all
  end

  def create
    @dropoff_location = DropoffLocation.create(dropoff_location_params)
  end

  def new
    @dropoff_location = DropoffLocation.new
  end

  def edit
    @dropoff_location = DropoffLocation.find(params[:id])
  end

  def show
    @dropoff_location = DropoffLocation.find(params[:id])
  end

  def update
    @dropoff_location = DropoffLocation.find(params[:id])
    @dropoff_location.update_attributes(dropoff_location_params)
    redirect_to @dropoff_location
  end

  def destroy
    DropoffLocation.find(params[:id]).destroy
    redirect_to dropoff_locations_path
  end

private
  def dropoff_location_params
    params.require(:dropoff_location).permit(:name, :address)
  end
end
