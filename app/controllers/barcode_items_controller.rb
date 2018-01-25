class BarcodeItemsController < ApplicationController
  def index
    @items = current_organization.items.barcoded_items
    @global = filter_params[:only_global]
    if @global
      @barcode_items = BarcodeItem.includes(:item).filter(filter_params)
    else
      @barcode_items = BarcodeItem.includes(:item).where(organization_id: current_organization.id).filter(filter_params)
    end
  end

  def create
    @barcode_item = current_organization.barcode_items.new(barcode_item_params)
    if @barcode_item.save
      msg = "New barcode added"
      msg += barcode_item_params[:global] == "1" ? " globally!" : " to your private set!"
      redirect_to barcode_items_path, notice: msg
    else
      flash[:alert] = "Something didn't work quite right -- try again?"
      render action: :new
    end
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
    if @barcode_item.update_attributes(barcode_item_params)
    redirect_to barcode_items_path, notice: "Barcode updated!"
    else
      flash[:alert] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    current_organization.barcode_items.find(params[:id]).destroy
    redirect_to barcode_items_path
  end

private
  def barcode_item_params
    params.require(:barcode_item).permit(:value, :item_id, :quantity, :global).merge(organization_id: current_organization.id)
  end

  def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:item_id, :less_than_quantity, :greater_than_quantity, :equal_to_quantity, :only_global)
  end
end
