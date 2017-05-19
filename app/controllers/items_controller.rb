class ItemsController < ApplicationController
  def index
    @items = Item.filter(filter_params)
    @categories = Item.categories
  end

  def create
    @item = Item.create(item_params)
    redirect_to @item, notice: "#{@item.name} added!"
  end

  def new
    @item = Item.new
  end

  def edit
    @item = Item.find(params[:id])
  end

  def show
    @item = Item.find(params[:id])
    @items_in_category = Item.in_same_category_as(@item)
    @storage_locations_containing = Item.storage_locations_containing(@item)
    @barcodes_for = Item.barcodes_for(@item)
  end

  def update
    @item = Item.find(params[:id])
    @item.update_attributes(item_params)
    redirect_to @item, notice: "#{@item.name} updated!"
  end

  def destroy
    Item.find(params[:id]).destroy
    redirect_to items_path
  end

private
  def item_params
    params.require(:item).permit(:name, :category)
  end

   def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:in_category)
  end
end
