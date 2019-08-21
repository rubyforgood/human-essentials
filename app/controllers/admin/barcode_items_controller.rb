# [Super Admin] - Manage globally available barcodes. The key difference here is that these barcodes
# will be associated with BaseItems, whereas user-barcodes are associated with regular Items.
class Admin::BarcodeItemsController < AdminController
  before_action :load_base_items, only: %i(edit index new)
  before_action :load_barcode_item, only: %i(edit update show destroy)

  def edit; end

  def update
    if @barcode_item.update(barcode_item_params)
      redirect_to admin_barcode_items_path, notice: "Updated Barcode Item!"
    else
      flash[:error] = "Failed to update this Barcode Item."
      render :edit
    end
  end

  def index
    @barcode_items = BarcodeItem.global
    @items = BaseItem.alphabetized.all
  end

  def new
    @barcode_item = BarcodeItem.new
  end

  def create
    @barcode_item = BarcodeItem.create(barcode_item_params.merge(barcodeable_type: "BaseItem"))
    if @barcode_item.save
      respond_to do |format|
        format.html { redirect_to admin_barcode_items_path, notice: "Barcode Item added!" }
        format.js
      end
    else
      load_base_items
      flash[:error] = "Failed to create Barcode Item."
      render :new
    end
  end

  def show; end

  def destroy
    if @barcode_item.destroy
      redirect_to admin_barcode_items_path, notice: "Barcode Item deleted!"
    else
      redirect_to admin_barcode_items_path, alert: "Failed to delete Barcode Item."
    end
  end

  private

  def load_base_items
    @base_items = BaseItem.alphabetized.all
  end

  def barcode_item_params
    params.require(:barcode_item).permit(:value, :barcodeable_id, :quantity)
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:barcodeable_id, :less_than_quantity, :greater_than_quantity, :equal_to_quantity, :base_item_id)
  end

  def load_barcode_item
    @barcode_item = BarcodeItem.find(params[:id])
  end
end
