# Provides full CRUD to Items. Every item is rooted in a BaseItem, but Diaperbanks have full control to do whatever
# they like with their own Items.
class ItemsController < ApplicationController
  def index
    @items = current_organization
      .items
      .includes(:base_item, :kit, :line_items, :request_units, :item_category)
      .alphabetized
      .class_filter(filter_params)
      .group('items.id')
    @items = @items.active unless params[:include_inactive_items]

    @item_categories = current_organization.item_categories.includes(:items).order('name ASC')
    @kits = current_organization.kits.includes(line_items: :item, inventory_items: :storage_location)
    @storages = current_organization.storage_locations.active_locations.order(id: :asc)

    @include_inactive_items = params[:include_inactive_items]
    @selected_base_item = filter_params[:by_base_item]

    @paginated_items = @items.page(params[:page])

    if Event.read_events?(current_organization)
      @inventory = View::Inventory.new(current_organization.id)
    end
    @items_by_storage_collection_and_quantity = ItemsByStorageCollectionAndQuantityQuery.call(organization: current_organization,
      inventory: @inventory,
      filter_params: filter_params)

    respond_to do |format|
      format.html
      if Event.read_events?(current_organization)
        format.csv { send_data Item.generate_csv_from_inventory(@items, @inventory), filename: "Items-#{Time.zone.today}.csv" }
      else
        format.csv { send_data Item.generate_csv(@items), filename: "Items-#{Time.zone.today}.csv" }
      end
    end
  end

  def create
    create = if Flipper.enabled?(:enable_packs)
      ItemCreateService.new(organization_id: current_organization.id, item_params: item_params, request_unit_ids:)
    else
      ItemCreateService.new(organization_id: current_organization.id, item_params: item_params)
    end
    result = create.call

    if result.success?
      redirect_to items_path, notice: "#{result.item.name} added!"
    else
      @base_items = BaseItem.without_kit.alphabetized
      # Define a @item to be used in the `new` action to be rendered with
      # the provided parameters. This is required to render the page again
      # with the error + the invalid parameters
      @item = current_organization.items.new(item_params)
      flash[:error] = result.error.record.errors.full_messages.to_sentence
      render action: :new
    end
  end

  def new
    @base_items = BaseItem.without_kit.alphabetized
    @item_categories = current_organization.item_categories
    @item = current_organization.items.new
  end

  def edit
    @base_items = BaseItem.without_kit.alphabetized
    @item_categories = current_organization.item_categories
    @item = current_organization.items.find(params[:id])
  end

  def show
    @item = current_organization.items.find(params[:id])
    if Event.read_events?(current_organization)
      @inventory = View::Inventory.new(current_organization.id)
      storage_location_ids = @inventory.storage_locations_for_item(@item.id)
      @storage_locations_containing = StorageLocation.find(storage_location_ids)
    else
      @storage_locations_containing = current_organization.items.storage_locations_containing(@item)
    end
    @barcodes_for = current_organization.items.barcodes_for(@item)
  end

  def update
    @item = current_organization.items.find(params[:id])
    @item.attributes = item_params
    deactivated = @item.active_changed? && !@item.active
    if deactivated && !@item.can_deactivate?
      @base_items = BaseItem.without_kit.alphabetized
      flash[:error] = "Can't deactivate this item - it is currently assigned to either an active kit or a storage location!"
      render action: :edit
      return
    end

    if update_item
      redirect_to items_path, notice: "#{@item.name} updated!"
    else
      @base_items = BaseItem.without_kit.alphabetized
      flash[:error] = "Something didn't work quite right -- try again? #{@item.errors.map { |error| "#{error.attribute}: #{error.message}" }}"
      render action: :edit
    end
  end

  def deactivate
    item = current_organization.items.find(params[:id])
    begin
      item.deactivate!
    rescue => e
      flash[:error] = e.message
      redirect_back(fallback_location: items_path)
      return
    end

    flash[:notice] = "#{item.name} has been deactivated."
    redirect_to items_path
  end

  def destroy
    item = current_organization.items.find(params[:id])
    item.destroy
    if item.errors.any?
      flash[:error] = item.errors.full_messages.join("\n")
      redirect_back(fallback_location: items_path)
      return
    end

    flash[:notice] = "#{item.name} has been removed."
    redirect_to items_path
  end

  def restore
    item = current_organization.items.find(params[:id])
    ActiveRecord::Base.transaction do
      Item.reactivate([item.id])
    end

    flash[:notice] = "#{item.name} has been restored."
    redirect_to items_path
  end

  def remove_category
    item = current_organization.items.find(params[:id])
    previous_category = item.item_category

    item.update!(item_category: nil)
    flash[:notice] = "#{item.name} has been removed from #{previous_category.name}."
    redirect_to item_category_path(previous_category)
  end

  private

  def clean_item_value_in_cents
    return nil unless params[:item][:value_in_cents]

    params[:item][:value_in_cents] = params[:item][:value_in_cents].gsub(/[$,.]/, "")
  end

  def clean_item_value_in_dollars
    return nil unless params[:item][:value_in_dollars]

    params[:item][:value_in_cents] = params[:item][:value_in_dollars].gsub(/[$,]/, "").to_d * 100
    params[:item].delete(:value_in_dollars)
  end

  def item_params
    # Memoize the value of this to prevent trying to
    # clean the values again which would result in an
    # error.
    return @item_params if @item_params

    clean_item_value_in_cents
    clean_item_value_in_dollars
    @item_params = params.require(:item).permit(
      :name,
      :item_category_id,
      :partner_key,
      :value_in_cents,
      :package_size,
      :on_hand_minimum_quantity,
      :on_hand_recommended_quantity,
      :distribution_quantity,
      :visible_to_partners,
      :active
    )
  end

  def request_unit_ids
    params.require(:item).permit(request_unit_ids: []).fetch(:request_unit_ids, [])
  end

  # We need to update both the item and the request_units together and fail together
  def update_item
    if Flipper.enabled?(:enable_packs)
      update_item_and_request_units
    else
      @item.save
    end
  end

  def update_item_and_request_units
    begin
      Item.transaction do
        @item.save!
        @item.sync_request_units!(request_unit_ids)
      end
    rescue
      return false
    end
    true
  end

  helper_method \
    def filter_params(_parameters = nil)
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_base_item, :include_inactive_items)
  end
end
