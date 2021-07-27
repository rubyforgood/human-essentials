# Provides full CRUD to Items. Every item is rooted in a BaseItem, but Diaperbanks have full control to do whatever
# they like with their own Items.
class ItemsController < ApplicationController
  def index
    @items = current_organization.items.includes(:base_item, :kit).alphabetized.class_filter(filter_params)
    @item_categories = current_organization.item_categories.includes(:items).order('name ASC')
    @kits = current_organization.kits.includes(line_items: :item, inventory_items: :storage_location)
    @storages = current_organization.storage_locations.order(id: :asc)

    @include_inactive_items = params[:include_inactive_items]
    @selected_base_item = filter_params[:by_base_item]
    @items_with_counts = ItemsByStorageCollectionQuery.new(organization: current_organization, filter_params: filter_params).call

    @items_by_storage_collection_and_quantity = ItemsByStorageCollectionAndQuantityQuery.new(organization: current_organization, filter_params: filter_params).call
    unless params[:include_inactive_items]
      @items = @items.active
      @items_with_counts = @items_with_counts.active
    end

    @paginated_items = @items.page(params[:page])

    respond_to do |format|
      format.html
      format.csv { send_data Item.generate_csv(@items), filename: "Items-#{Time.zone.today}.csv" }
    end
  end

  def create
    create = ItemCreateService.new(organization_id: current_organization.id, item_params: item_params)
    result = create.call

    if result.success?
      redirect_to items_path, notice: "#{result.item.name} added!"
    else
      @base_items = BaseItem.without_kit.alphabetized
      # Define a @item to be used in the `new` action to be rendered with
      # the provided parameters. This is required to render the page again
      # with the error + the invalid parameters
      @item = current_organization.items.new(item_params)

      flash[:error] = "Something didn't work quite right -- try again?"
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
    @storage_locations_containing = current_organization.items.storage_locations_containing(@item)
    @barcodes_for = current_organization.items.barcodes_for(@item)
  end

  def update
    @item = current_organization.items.find(params[:id])
    if @item.update(item_params)
      redirect_to items_path, notice: "#{@item.name} updated!"
    else
      @base_items = BaseItem.without_kit.alphabetized
      flash[:error] = "Something didn't work quite right -- try again? #{@item.errors.map { |attr, msg| "#{attr}: #{msg}" }}"
      render action: :edit
    end
  end

  def destroy
    item = current_organization.items.find(params[:id])
    ActiveRecord::Base.transaction do
      item.destroy
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

  helper_method \
    def filter_params(_parameters = nil)
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_base_item, :include_inactive_items)
  end
end
