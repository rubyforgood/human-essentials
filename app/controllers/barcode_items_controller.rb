class BarcodeItemsController < ApplicationController
  def index
    @barcode_items = BarcodeItem.all
  end

  def create
    Rails.logger.info barcode_item_params.inspect
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
end
