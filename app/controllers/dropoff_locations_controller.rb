class DropoffLocationsController < ApplicationController
  def index
    @dropoff_locations = current_organization.dropoff_locations.all.order(:name)
  end

  def create
    @dropoff_location = current_organization.dropoff_locations.create(dropoff_location_params)
    if @dropoff_location.save
      redirect_to dropoff_locations_path, notice: "New dropoff location added!"
    else
      flash[:alert] = "There was an error with this dropoff location, try again?"
      render action: :new
    end      
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
    redirect_to dropoff_locations_path, notice: "#{@dropoff_location.name} updated!"
  end

  def import_csv
    if params[:file].nil?
      redirect_back(fallback_location: dropoff_locations_path(organization_id: current_organization))
      flash[:alert] = "No file was attached!"
    else
      filepath = params[:file].read
      DropoffLocation.import_csv(filepath, current_organization.id)
      flash[:notice] = "Dropoff locations were imported successfully!"
      redirect_back(fallback_location: dropoff_locations_path(organization_id: current_organization))
    end
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
