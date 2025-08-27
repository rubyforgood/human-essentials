# Provides Full CRUD+ for Storage Locations, which are digital representations of inventory holdings
class StorageLocationsController < ApplicationController
  include Importable

  Struct.new('OmittedInventoryItem', :item) do
    def quantity
      0
    end
  end

  def index
    @inventory = View::Inventory.new(current_organization.id)
    @selected_item_category = filter_params[:containing]
    @items = StorageLocation.items_inventoried(current_organization, @inventory)
    @include_inactive_storage_locations = params[:include_inactive_storage_locations]
    @storage_locations = current_organization.storage_locations.alphabetized

    if filter_params[:containing].present?
      containing_ids = @inventory.storage_locations.keys.select do |sl|
        @inventory.quantity_for(item_id: filter_params[:containing], storage_location: sl).positive?
      end
      @storage_locations = @storage_locations.where(id: containing_ids)
    else
      @storage_locations = @storage_locations.class_filter(filter_params)
    end

    unless @include_inactive_storage_locations
      @storage_locations = @storage_locations.kept
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data StorageLocation.generate_csv_from_inventory(@storage_locations, @inventory, current_organization), filename: "StorageLocations-#{Time.zone.today}.csv"
      end
    end
  end

  def create
    @storage_location = current_organization.storage_locations.new(storage_location_params)
    if @storage_location.save
      redirect_to storage_locations_path, notice: "New storage location added!"
    else
      flash.now[:error] = "Something didn't work quite right -- try again?"
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
    version_date = params[:version_date].presence&.to_date
    # TODO: Find a way to do these with less hard SQL. These queries have to be manually updated because they're not in-sync with the Model
    @items_out = ItemsOutQuery.new(organization: current_organization, storage_location: @storage_location).call
    @items_out_total = ItemsOutTotalQuery.new(organization: current_organization, storage_location: @storage_location).call
    @items_in = ItemsInQuery.new(organization: current_organization, storage_location: @storage_location).call
    @items_in_total = ItemsInTotalQuery.new(organization: current_organization, storage_location: @storage_location).call
    if View::Inventory.within_snapshot?(current_organization.id, version_date)
      @inventory = View::Inventory.new(current_organization.id, event_time: version_date)
    else
      @legacy_inventory = View::Inventory.legacy_inventory_for_storage_location(
        current_organization.id,
        @storage_location.id,
        version_date
      )
    end

    respond_to do |format|
      format.html
      format.csv { send_data @storage_location.to_csv }
      format.xls
    end
  end

  def import_inventory
    if params[:file].nil?
      redirect_back(fallback_location: storage_locations_path)
      flash[:error] = "No file was attached!"
    else
      filepath = params[:file].read
      StorageLocation.import_inventory(filepath, current_organization.id, params[:storage_location])
      flash[:notice] = "Inventory imported successfully!"
      redirect_back(fallback_location: storage_locations_path)
    end
  rescue Errors::InventoryAlreadyHasItems => e
    flash[:error] = e.message
    redirect_back(fallback_location: storage_locations_path(organization_id: current_organization))
  end

  def update
    @storage_location = current_organization.storage_locations.find(params[:id])
    if @storage_location.update(storage_location_params)
      redirect_to storage_locations_path, notice: "#{@storage_location.name} updated!"
    else
      flash.now[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def deactivate
    @storage_location = current_organization.storage_locations.kept.find(params[:storage_location_id])
    svc = StorageLocationDeactivateService.new(storage_location: @storage_location)
    if svc.call
      redirect_to storage_locations_path, notice: "Storage Location deactivated successfully"
    else
      redirect_back(fallback_location: storage_locations_path,
        error: "Cannot deactivate storage location containing inventory items with non-zero quantities")
    end
  end

  def reactivate
    @storage_location = current_organization.storage_locations.all.find(params[:storage_location_id])
    if @storage_location.undiscard!
      redirect_to storage_locations_path, notice: "Storage Location reactivated successfully"
    else
      redirect_back(fallback_location: storage_locations_path, error: "Something didn't work quite right -- try again?")
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
    @items = View::Inventory.items_for_location(StorageLocation.find(params[:id]),
      include_omitted: params[:include_omitted_items] == "true")
    respond_to do |format|
      format.json { render :event_inventory }
    end
  end

  private

  def storage_location_params
    params.require(:storage_location).permit(:name, :address, :square_footage, :warehouse_type, :time_zone)
  end

  def include_omitted_items(existing_item_ids = [])
    current_organization.items.where.not(id: existing_item_ids).collect do |item|
      Struct::OmittedInventoryItem.new(item)
    end
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:containing)
  end
end
