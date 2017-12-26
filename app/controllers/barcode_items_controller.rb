class BarcodeItemsController < ApplicationController
  def index
    @barcode_items = current_organization.barcode_items.includes(:item).filter(filter_params)
    @items = current_organization.items.barcoded_items
  end

  def create
    msg = "New barcode added"
    # FIXME: The "global" thing is a bit klunky. Perhaps this can be done better?
    global = barcode_item_params.delete(:global)
    global = nil unless (global.present? && global.to_i > 0)
    if (global)
      @barcode_item = BarcodeItem.create(barcode_item_params)
      msg += " globally!"
    else
      @barcode_item = current_organization.barcode_items.create(barcode_item_params)
      msg += " to your private set!"
    end
    redirect_to barcode_items_path, notice: msg
  end

  def new
    @barcode_item = current_organization.barcode_items.new
    @items = current_organization.items
  end

  def edit
    @barcode_item = current_organization.barcode_items.includes(:item).find(params[:id])
    @items = current_organization.items
  end

  def show
    @barcode_item = current_organization.barcode_items.includes(:item).find(params[:id])
  end

  def find
    @barcode_item = current_organization.barcode_items.includes(:item).find_by!(value: barcode_item_params[:value])
    respond_to do |format|
      format.json { render json: @barcode_item.to_json }
    end
  end

  def update
    @barcode_item = current_organization.barcode_items.find(params[:id])
    @barcode_item.update_attributes(barcode_item_params)
    redirect_to barcode_items_path, notice: "Barcode updated!"
  end

  def destroy
    current_organization.barcode_items.find(params[:id]).destroy
    redirect_to barcode_items_path
  end

private
  def barcode_item_params
    params.require(:barcode_item).permit(:value, :item_id, :quantity, :global)
  end

  def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:item_id, :less_than_quantity, :greater_than_quantity, :equal_to_quantity)
  end
end
