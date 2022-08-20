# [Super Admin] Manage the BaseItems -- this is the only place in the app where Base Items can be
# added / modified. Base Items are both the template and common thread for regular Items
class Admin::BaseItemsController < AdminController
  def edit
    @base_item = BaseItem.find(params[:id])
  end

  def update
    @base_item = BaseItem.find(params[:id])
    if @base_item.update(base_item_params)
      redirect_to admin_base_items_path, notice: "Updated base item!"
    else
      flash[:error] = "Failed to update this base item."
      render :edit
    end
  end

  def index
    @base_items = BaseItem.alphabetized.all
  end

  def new
    @base_item = BaseItem.new
  end

  def create
    @base_item = BaseItem.create(base_item_params)
    if @base_item.save
      redirect_to admin_base_items_path, notice: "Base Item added!"
    else
      flash[:error] = "Failed to create Base Item."
      render :new
    end
  end

  def show
    @base_item = BaseItem.includes(items: [:organization]).find(params[:id])
    @items = @base_item.items
  end

  def destroy
    @base_item = BaseItem.includes(:items).find(params[:id])
    if @base_item.items.any? && @base_item.destroy
      redirect_to admin_base_items_path, notice: "Base Item deleted!"
    else
      redirect_to admin_base_items_path, alert: "Failed to delete Base Item. Are there still items attached?"
    end
  end

  private

  def base_item_params
    params.require(:base_item).permit(:name, :partner_key)
  end
end
