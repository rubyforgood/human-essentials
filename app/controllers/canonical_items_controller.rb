class CanonicalItemsController < ApplicationController
  before_action :authorize_user

  def edit
    @canonical_item = CanonicalItem.find(params[:id])
  end

  def update
    @canonical_item = CanonicalItem.find(params[:id])
    if @canonical_item.update(canonical_item_params)
      redirect_to canonical_items_path, notice: "Updated canonical item!"
    else
      flash[:error] = "Failed to update this canonical item."
      render :edit
    end
  end

  def index
    @canonical_items = CanonicalItem.all
  end

  def new
    @canonical_item = CanonicalItem.new
  end

  def create
    @canonical_item = CanonicalItem.create(canonical_item_params)
    if @canonical_item.save
      redirect_to canonical_items_path, notice: "Canonical Item added!"
    else
      flash[:error] = "Failed to create Canonical Item."
      render :new
    end
  end

  def show
    @canonical_item = CanonicalItem.includes(items: [:organization]).find(params[:id])
    @items = @canonical_item.items
  end

  # TODO: If there are associated Items, they should be migrated prior to deletion
  def destroy
    @canonical_item = CanonicalItem.includes(:items).find(params[:id])
    if !@canonical_item.items.empty? && @canonical_item.destroy
      redirect_to canonical_items_path, notice: "Canonical Item deleted!"
    else
      redirect_to admins_path, alert: "Failed to delete Canonical Item. Are there still items attached?"
    end
  end

  private

  def authorize_user
    verboten! unless current_user.organization_admin
  end

  def canonical_item_params
    params.require(:canonical_item).permit(:name, :key, :category)
  end
end
