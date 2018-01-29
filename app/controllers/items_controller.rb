class ItemsController < ApplicationController
  def index
    @show_quantity = filter_params(:show_quantity)[:show_quantity]

    if @show_quantity == "0" || @show_quantity.nil? # only items
    @items = current_organization.items.alphabetized.filter(filter_params)
    elsif @show_quantity == "1" # items and quantity
    @items = current_organization.
        items.
        joins(' LEFT OUTER JOIN "inventory_items" ON "inventory_items"."item_id" = "items"."id"').
        select('items.id, items.name, items.category, items.barcode_count, sum(inventory_items.quantity) as quantity').
        group('items.id, items.name').order(name: :asc).filter(filter_params)
    elsif @show_quantity == "2" # items, quantity and storage name
      @items = current_organization.
          items.
          joins(' LEFT OUTER JOIN "inventory_items" ON "inventory_items"."item_id" = "items"."id"').
          joins(' LEFT OUTER JOIN "storage_locations" ON "storage_locations"."id" = "inventory_items"."storage_location_id"').
          select('items.id, items.name, items.category, items.barcode_count, storage_locations.name as storage_name, storage_locations.id as storage_id, sum(inventory_items.quantity) as quantity').
          group('storage_locations.name, storage_locations.id, items.id, items.name').order(name: :asc).filter(filter_params)
    end

    if @show_quantity == "2"
    @storages = current_organization.storage_locations.order(id: :asc)
    @row_collection = Hash.new
    new_storage_collection
    end

    @categories = Item.categories
    @selected_category = filter_params[:in_category]
  end

  def create
    @item = current_organization.items.new(item_params)
    if @item.save
    redirect_to items_path, notice: "#{@item.name} added!"
      else
      flash[:alert] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @item = current_organization.items.new
  end

  def edit
    @item = current_organization.items.find(params[:id])
  end

  def show
    @item = current_organization.items.find(params[:id])
    @items_in_category = Item.in_same_category_as(@item)
    @storage_locations_containing = Item.storage_locations_containing(@item)
    @barcodes_for = Item.barcodes_for(@item)
  end

  def update
    @item = current_organization.items.find(params[:id])
    if @item.update_attributes(item_params)
    redirect_to items_path, notice: "#{@item.name} updated!"
    else
      flash[:alert] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    current_organization.items.find(params[:id]).destroy
    redirect_to items_path
  end

  def new_storage_collection
    @storages.each do |storage|
      @row_collection[storage.id] = ''
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
    params.require(:item).permit(:name, :category)
  end

  def filter_params(parameter = :in_category)
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(parameter)
  end
end
