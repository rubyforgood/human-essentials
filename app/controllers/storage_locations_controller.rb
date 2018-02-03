class StorageLocationsController < ApplicationController
  def index
    @items = current_organization.storage_locations.items_inventoried
    @storage_locations = current_organization.storage_locations.includes(:inventory_items).filter(filter_params)
  end

  def create
    @storage_location = current_organization.storage_locations.new(storage_location_params)
    if @storage_location.save
    redirect_to storage_locations_path, notice: "New storage location added!"
    else
      flash[:alert] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @storage_location = current_organization.storage_locations.new
  end

  def edit
    @storage_location = current_organization.storage_locations.find(params[:id])
  end

  def show
    @storage_location = current_organization.storage_locations.find(params[:id])
    respond_to do |format|
      format.html
      format.csv { send_data @storage_location.to_csv }
      format.xls 
    end
  end

  def import_inventory
    if params[:file].nil?
      redirect_back(fallback_location: storage_locations_path(organization_id: current_organization))
      flash[:alert] = "No file was attached!"
    else
      filepath = params[:file].read
      StorageLocation.import_inventory(filepath, current_organization.id, params[:storage_location])
      flash[:notice] = "Inventory imported successfully!"
      redirect_back(fallback_location: storage_locations_path(organization_id: current_organization))
    end
  end    

  def import_csv
    if params[:file].nil?
      redirect_back(fallback_location: storage_locations_path(organization_id: current_organization))
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
    if @storage_location.update_attributes(storage_location_params)
    redirect_to storage_locations_path, notice: "#{@storage_location.name} updated!"
    else
      flash[:alert] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
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
