class ItemsController < ApplicationController
  def index
    @items = Item.all
  end

  def create
    @item = Item.create(item_params)
    redirect_to(@item)
  end

  def new
    @item = Item.new
  end

  def edit
    @item = Item.find(params[:id])
  end

  def show
    @item = Item.find(params[:id])
  end

  def update
    @item = Item.find(params[:id])
    @item.update_attributes(item_params)
  end

  def destroy
    Item.find(params[:id]).destroy
    redirect_to items_path
  end

private
  def item_params
    params.require(:item).permit(:name, :category)
  end
end
