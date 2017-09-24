class StorageLocationsController < ApplicationController
  def index
    @items = current_organization.storage_locations.items_inventoried
    @storage_locations = current_organization.storage_locations.includes(:inventory_items).filter(filter_params)
  end

  def create
    @storage_location = current_organization.storage_locations.create(storage_location_params)
    redirect_to @storage_location, notice: "New storage location added!"
  end

  def new
    @storage_location = current_organization.storage_locations.new
  end

  def edit
    @storage_location = current_organization.storage_locations.find(params[:id])
  end

  def show
    @storage_location = current_organization.storage_locations.find(params[:id])
  end

  def import_csv
    if params[:file].nil?
      redirect_back(fallback_location: admin_people_url)
      flash[:alert] = "No file was attached!"
    else
      filepath = params[:file].read
      StorageLocation.import_csv(filepath, current_organization.id)
      flash[:notice] = "Storage locations were imported successfully!"
      redirect_back(fallback_location: storage_locations_path(organization_id: current_organization))
    end
  end

  # TODO - the intake! method needs to be worked into this controller somehow.
  # TODO - the distribute! method needs to be worked into this controller somehow
  def update
    @storage_location = current_organization.storage_locations.find(params[:id])
    @storage_location.update_attributes(storage_location_params)
    redirect_to @storage_location, notice: "#{@storage_location.name} updated!"
  end

  def destroy
    current_organization.storage_locations.find(params[:id]).destroy
    redirect_to storage_locations_path
  end

  def inventory
    @storage_location = current_organization.storage_locations.includes(inventory_items: :item).find(params[:id])
    respond_to :json
  end

private
  def storage_location_params
    params.require(:storage_location).permit(:name, :address)
  end

  def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:containing)
  end
end
