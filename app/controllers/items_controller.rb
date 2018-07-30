class ItemsController < ApplicationController
  def index
    @items = current_organization.items.includes(:canonical_item).alphabetized.filter(filter_params)
    @storages = current_organization.storage_locations.order(id: :asc)
    hack_for_autoload_query_object_classes_to_work
    @items_with_counts = Query::ItemsByStorageCollection.new(organization: current_organization, filter_params: filter_params).call
    @items_by_storage_collection_and_quantity = Query::ItemsByStorageCollectionAndQuantity.new(organization: current_organization, filter_params: filter_params).call
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

  private

  # Need to trick autoload to find Query::ItemsByStorageCollection(AndQuantity)
  def hack_for_autoload_query_object_classes_to_work
    begin
      ::ItemsByStorageCollection
    rescue LoadError
    end
    begin
      ::ItemsByStorageCollectionAndQuantity
    rescue LoadError
    end
  end

  def item_params
    params.require(:item).permit(:name, :category, :canonical_item_id)
  end

  def filter_params(parameters = nil)
    parameters = (%i(in_category by_canonical_item) + [parameters]).flatten.uniq
    return {} unless params.key?(:filters)
    params.require(:filters).slice(*parameters)
  end
end
