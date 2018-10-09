class Admin::BarcodeItemsController < AdminController
  before_action :preload_canonical_items, only: [:edit, :index, :new]

  def edit
    @barcode_item = BarcodeItem.find(params[:id])
  end

  def update
    @barcode_item = BarcodeItem.find(params[:id])
    if @barcode_item.update(barcode_item_params)
      redirect_to admin_barcode_items_path, notice: "Updated Barcode Item!"
    else
      flash[:error] = "Failed to update this Barcode Item."
      render :edit
    end
  end

  def index
    @barcode_items = BarcodeItem.where(global: true)
  end

  def new
    @barcode_item = BarcodeItem.new
  end

  def create
    @barcode_item = BarcodeItem.create(barcode_item_params.merge(global: true, barcodeable_type: "CanonicalItem"))
    if @barcode_item.save
      redirect_to admin_barcode_items_path, notice: "Barcode Item added!"
    else
      preload_canonical_items
      flash[:error] = "Failed to create Barcode Item."
      render :new
    end
  end

  def show
    @barcode_item = BarcodeItem.includes(:barcodeable).find(params[:id])
  end

  def destroy
    @barcode_item = BarcodeItem.find(params[:id])
    if @barcode_item.destroy
      redirect_to admin_barcode_items_path, notice: "Barcode Item deleted!"
    else
      redirect_to admin_barcode_items_path, alert: "Failed to delete Barcode Item."
    end
  end

  private

  def preload_canonical_items
    @canonical_items ||= CanonicalItem.all
  end

  def barcode_item_params
    params.require(:barcode_item).permit(:value, :barcodeable_id, :quantity)
  end

  def filter_params
    return {} unless params.key?(:filters)
    params.require(:filters).slice(:barcodeable_id, :less_than_quantity, :greater_than_quantity, :equal_to_quantity, :include_global, :canonical_item_id)
  end
end
