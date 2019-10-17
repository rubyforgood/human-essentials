# Provides full CRUD to Items. Every item is rooted in a BaseItem, but Diaperbanks have full control to do whatever
# they like with their own Items.
class ItemsController < ApplicationController
  def index
    @items = current_organization.items.includes(:base_item).alphabetized.class_filter(filter_params)
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
  end

  def create
    @item = current_organization.items.new(item_params)
    if @item.save
      redirect_to items_path, notice: "#{@item.name} added!"
    else
      @base_items = BaseItem.alphabetized
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @base_items = BaseItem.alphabetized
    @item = current_organization.items.new
  end

  def edit
    @base_items = BaseItem.alphabetized
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
      @base_items = BaseItem.alphabetized
      flash[:error] = "Something didn't work quite right -- try again?"
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

  def clean_purchase_amount
    return nil unless params[:item][:value_in_cents]

    params[:item][:value_in_cents] = params[:item][:value_in_cents].gsub(/[$,.]/, "")
  end

  def item_params
    clean_purchase_amount
    params.require(:item).permit(
      :name,
      :partner_key,
      :value_in_cents,
      :package_size,
      :on_hand_minimum_quantity,
      :on_hand_recommended_quantity,
      :distribution_quantity
    )
  end

  def filter_params(_parameters = nil)
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:by_base_item, :include_inactive_items)
  end
end
