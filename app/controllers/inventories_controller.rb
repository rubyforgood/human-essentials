class InventoriesController < ApplicationController
  def index
    @items = Inventory.items_inventoried
    @inventories = Inventory.includes(:inventory_items).filter(filter_params)
  end

  def create
    @inventory = Inventory.create(inventory_params)
    redirect_to @inventory, notice: "New inventory added!"
  end

  def new
    @inventory = Inventory.new
  end

  def edit
    @inventory = Inventory.find(params[:id])
  end

  def show
    @inventory = Inventory.find(params[:id])
  end

  # TODO - the intake! method needs to be worked into this controller somehow.
  # TODO - the distribute! method needs to be worked into this controller somehow
  def update
    @inventory = Inventory.find(params[:id])
    @inventory.update_attributes(inventory_params)
    redirect_to @inventory, notice: "#{@inventory.name} updated!"
  end

  def destroy
    Inventory.find(params[:id]).destroy
    redirect_to inventories_path
  end

private
  def inventory_params
    params.require(:inventory).permit(:name, :address)
  end

  def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:containing)
  end
end
