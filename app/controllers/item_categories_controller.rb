class ItemCategoriesController < ApplicationController
  def new
    @item_category = ItemCategory.new
  end

  def create
    @item_category = ItemCategory.new(organization: current_organization)
    @item_category.assign_attributes(item_category_params)

    if @item_category.save
      redirect_to items_path
    else
      render :new
    end
  end

  def show
    @item_category = current_organization.item_categories.includes(:items).find_by(id: params[:id])
  end

  def edit
    @item_category = current_organization.item_categories.find_by(id: params[:id])
  end

  def update
    @item_category = current_organization.item_categories.find_by(id: params[:id])
    @item_category.assign_attributes(item_category_params)

    if @item_category.save
      redirect_to item_category_path(@item_category)
    else
      render :edit
    end
  end

  def destroy
    @item_category = current_organization.item_categories.find_by(id: params[:id])
    if @item_category.items.exists?
      flash[:error] = "Cannot delete item category because it has associated items."
      render :show, status: :unprocessable_entity
    else
      @item_category.destroy
      flash[:notice] = "#{@item_category.name} has been deleted."
      redirect_to items_path
    end
  end

  private

  def item_category_params
    params.require(:item_category).permit(:name, :description)
  end
end
