class BarcodeItemsController < ApplicationController
  def index
    @barcode_items = BarcodeItem.includes(:item).filter(filter_params)
    @items = BarcodeItem.barcoded_items
  end

  def create
    @barcode_item = BarcodeItem.create(barcode_item_params)
    redirect_to barcode_item_path(@barcode_item), notice: "New barcode added!"
  end

  def new
    @barcode_item = BarcodeItem.new
    @items = Item.all
  end

  def edit
    @barcode_item = BarcodeItem.find(params[:id])
    @items = Item.all
  end

  def show
    @barcode_item = BarcodeItem.find(params[:id])
  end

  def update
    @barcode_item = BarcodeItem.find(params[:id])
    @barcode_item.update_attributes(barcode_item_params)
    redirect_to barcode_item_path(@barcode_item), notice: "Barcode updated!"
  end

  def destroy
    BarcodeItem.find(params[:id]).destroy
    redirect_to barcode_items_path
  end

private
  def barcode_item_params
    params.require(:barcode_item).permit(:value, :item_id, :quantity)
  end

  def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:item_id, :less_than_quantity, :greater_than_quantity, :equal_to_quantity)
  end
end
