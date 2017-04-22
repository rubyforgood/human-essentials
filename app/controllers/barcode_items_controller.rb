class BarcodeItemsController < ApplicationController
  def index
    @barcode_items = BarcodeItem.all
  end

  def create
    @barcode_item = BarcodeItem.create(barcode_item_params)
    redirect_to(barcode_item_path(@barcode_item))
  end

  def new
    @barcode_item = BarcodeItem.new
  end

  def edit
    @barcode_item = BarcodeItem.find(params[:id])
  end

  def show
    @barcode_item = BarcodeItem.find(params[:id])
  end

  def update
    @barcode_item = BarcodeItem.find(params[:id])
    BarcodeItem.update_attributes(barcode_item_params)
    redirect_to barcode_item_path(@barcode_item)
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
