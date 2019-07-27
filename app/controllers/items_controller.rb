# Provides full CRUD to Items. Every item is rooted in a BaseItem, but Diaperbanks have full control to do whatever
# they like with their own Items.
class ItemsController < ApplicationController
  def index
    @items = current_organization.items.active.includes(:base_item).alphabetized.class_filter(filter_params)
    @storages = current_organization.storage_locations.order(id: :asc)
    @items_with_counts = ItemsByStorageCollectionQuery.new(organization: current_organization, filter_params: filter_params).call
    @items_by_storage_collection_and_quantity = ItemsByStorageCollectionAndQuantityQuery.new(organization: current_organization, filter_params: filter_params).call
  end

  def create
    @item = current_organization.items.new(item_params)
    if @item.save
      redirect_to items_path, notice: "#{@item.name} added!"
    else
      @base_items = BaseItem.alphabetized
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @base_items = BaseItem.alphabetized
    @item = current_organization.items.new
  end

  def edit
    @base_items = BaseItem.alphabetized
    @item = current_organization.items.find(params[:id])
  end

  def show
    @item = current_organization.items.find(params[:id])
    @storage_locations_containing = current_organization.items.storage_locations_containing(@item)
    @barcodes_for = current_organization.items.barcodes_for(@item)
  end

  def update
    @item = current_organization.items.find(params[:id])
    if @item.update(item_params)
      redirect_to items_path, notice: "#{@item.name} updated!"
    else
      @base_items = BaseItem.alphabetized
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    item = current_organization.items.find(params[:id])
    ActiveRecord::Base.transaction do
      item.destroy
    end

    flash[:notice] = "#{item.name} has been removed."
    redirect_to items_path
  end

  private

  def clean_purchase_amount
    return nil unless params[:item][:value_in_cents]

    params[:item][:value_in_cents] = params[:item][:value_in_cents].gsub(/[$,.]/, "")
  end

  def item_params
    clean_purchase_amount
    params.require(:item).permit(:name, :partner_key, :value_in_cents, :package_size, :distribution_quantity)
  end

  def filter_params(parameters = nil)
    parameters = (%i(by_base_item) + [parameters]).flatten.uniq
    return {} unless params.key?(:filters)

    params.require(:filters).slice(*parameters)
  end
end
