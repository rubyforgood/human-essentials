class CanonicalItemsController < ApplicationController
  before_action :authorize_user

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

  private

  def authorize_user
    verboten! unless current_user.organization_admin
  end

  def canonical_item_params
    params.require(:canonical_item).permit(:name, :key, :category)
  end
end
