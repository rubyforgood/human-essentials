# Provides Full CRUD+ for Storage Locations, which are digital representations of inventory holdings
class StorageLocationsController < ApplicationController
  include Importable

  def index
    @selected_item_category = filter_params[:containing]
    @items = current_organization.storage_locations.items_inventoried
    @storage_locations = current_organization.storage_locations.alphabetized.includes(:inventory_items).class_filter(filter_params)

    respond_to do |format|
      format.html
      format.csv { send_data StorageLocation.generate_csv(@storage_locations), filename: "StorageLocations-#{Time.zone.today}.csv" }
    end
  end

  def create
    @storage_location = current_organization.storage_locations.new(storage_location_params)
    if @storage_location.save
      redirect_to storage_locations_path, notice: "New storage location added!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @storage_location = current_organization.storage_locations.new
  end

  def edit
    @storage_location = current_organization.storage_locations.find(params[:id])
  end

  # TODO: Move these queries to Query Object
  def show
    @storage_location = current_organization.storage_locations.find(params[:id])
    # TODO: Find a way to do these with less hard SQL. These queries have to be manually updated because they're not in-sync with the Model
    @items_out = ItemsOutQuery.new(organization: current_organization, storage_location: @storage_location).call
    @items_out_total = ItemsOutTotalQuery.new(organization: current_organization, storage_location: @storage_location).call
    @items_in = ItemsInQuery.new(organization: current_organization, storage_location: @storage_location).call
    @items_in_total = ItemsInTotalQuery.new(organization: current_organization, storage_location: @storage_location).call

    respond_to do |format|
      format.html
      format.csv { send_data @storage_location.to_csv }
      format.xls
    end
  end

  def import_inventory
    if params[:file].nil?
      redirect_back(fallback_location: storage_locations_path(organization_id: current_organization))
      flash[:error] = "No file was attached!"
    else
      filepath = params[:file].read
      StorageLocation.import_inventory(filepath, current_organization.id, params[:storage_location])
      flash[:notice] = "Inventory imported successfully!"
      redirect_back(fallback_location: storage_locations_path(organization_id: current_organization))
    end
  end

  def update
    @storage_location = current_organization.storage_locations.find(params[:id])
    if @storage_location.update(storage_location_params)
      redirect_to storage_locations_path, notice: "#{@storage_location.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    @storage_location = current_organization.storage_locations.find(params[:id])

    if @storage_location.destroy
      redirect_to storage_locations_path, notice: "Storage Location deleted successfully"
    else
      flash[:error] = @storage_location.errors.full_messages.join(', ')
      redirect_to storage_locations_path
    end
  end

  def inventory
    @inventory_items = current_organization.storage_locations
                                           .includes(inventory_items: :item)
                                           .find(params[:id])
                                           .inventory_items
    respond_to :json
  end

  private

  def storage_location_params
    params.require(:storage_location).permit(:name, :address, :square_footage, :warehouse_type)
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:containing)
  end
end
