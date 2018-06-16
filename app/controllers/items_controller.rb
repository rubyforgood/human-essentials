class ItemsController < ApplicationController
  def index
    @items = current_organization.items.includes(:canonical_item).alphabetized.filter(filter_params)
    @items_with_counts = current_organization.
        items.
        joins(' LEFT OUTER JOIN "inventory_items" ON "inventory_items"."item_id" = "items"."id"').
        joins(' LEFT OUTER JOIN "storage_locations" ON "storage_locations"."id" = "inventory_items"."storage_location_id"').
        select('items.id, items.name, items.category, items.barcode_count, storage_locations.name as storage_name, storage_locations.id as storage_id, sum(inventory_items.quantity) as quantity').
        group('storage_locations.name, storage_locations.id, items.id, items.name').order(name: :asc).filter(filter_params)

    @storages = current_organization.storage_locations.order(id: :asc)
    @row_collection = Hash.new
    new_storage_collection
  end

  def create
    @item = current_organization.items.new(item_params)
    if @item.save
      redirect_to items_path, notice: "#{@item.name} added!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @canonical_items = CanonicalItem.all
    @item = current_organization.items.new
  end

  def edit
    @canonical_items = CanonicalItem.all
    @item = current_organization.items.find(params[:id])
  end

  def show
    @item = current_organization.items.find(params[:id])
    @items_in_category = current_organization.items.in_same_category_as(@item)
    @storage_locations_containing = current_organization.items.storage_locations_containing(@item)
    @barcodes_for = current_organization.items.barcodes_for(@item)
  end

  def update
    @item = current_organization.items.find(params[:id])
    if @item.update(item_params)
      redirect_to items_path, notice: "#{@item.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    current_organization.items.find(params[:id]).destroy
    redirect_to items_path
  end

  def new_storage_collection
    @storages.each do |storage|
      @row_collection[storage.id] = ""
    end
    @row_collection[:item_quantity] = 0
    @row_collection[:item_id] = nil
  end
  helper_method :new_storage_collection

  def update_storage_collection(item)
    @row_collection[item.storage_id] = item.quantity
    @row_collection[:item_id] = item.id
    @row_collection[:item_name] = item.name
    @row_collection[:item_category] = item.category
    @row_collection[:item_barcode_count] = item.barcode_count
    @row_collection[:item_quantity] += item.quantity.nil? ? 0 : item.quantity
  end
  helper_method :update_storage_collection

  private

  def item_params
    params.require(:item).permit(:name, :category, :canonical_item_id)
  end

  def filter_params(parameters = nil)
    parameters = (%i(in_category by_canonical_item) + [parameters]).flatten.uniq
    return {} unless params.key?(:filters)
    params.require(:filters).slice(*parameters)
  end
end
