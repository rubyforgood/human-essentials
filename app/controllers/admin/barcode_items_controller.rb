class Admin::BarcodeItemsController < AdminController
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
    @barcode_items = BarcodeItem.all
  end

  def new
    @barcode_item = BarcodeItem.new
  end

  def create
    @barcode_item = BarcodeItem.create(barcode_item_params)
    if @barcode_item.save
      redirect_to admin_barcode_items_path, notice: "Barcode Item added!"
    else
      flash[:error] = "Failed to create Barcode Item."
      render :new
    end
  end

  def show
    @barcode_item = BarcodeItem.includes(items: [:organization]).find(params[:id])
    @items = @barcode_item.items
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

  def barcode_item_params
    params.require(:barcode_item).permit(:name, :key, :category)
  end
end
