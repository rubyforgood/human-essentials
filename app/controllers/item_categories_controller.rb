class ItemCategoriesController < ApplicationController
  def new
  end

  def index
    @item_categories = current_organization.item_categories
  end

  def show
  end

  def edit
  end
end
