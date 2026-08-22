# [Super Admin] - Manage globally available barcodes. The key difference here is that these barcodes
# will be associated with BaseItems, whereas user-barcodes are associated with regular Items.
class Admin::BarcodeItemsController < AdminController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  before_action :load_base_items, only: %i(edit index new)
  before_action :load_barcode_item, only: %i(edit update show destroy)

  def edit; end

  def update
    if @barcode_item.update(barcode_item_params)
      redirect_to admin_barcode_items_path, notice: "Updated Barcode Item!"
    else
      flash.now[:error] = "Failed to update this Barcode Item."
      render :edit
    end
  end

  def index
    @items = BaseItem.alphabetized.all
    @selected_barcodeable_id = filter_params[:barcodeable_id]
    # `class_filter` was never called here, so the filter select on this page had no effect at
    # all: choosing a base item reloaded the same full list with the choice in the query string.
    @barcode_items = BarcodeItem.global.includes(:barcodeable).class_filter(filter_params)
    @paginated_barcode_items = @barcode_items.page(params[:page]).per(Pagination::COMPACT)
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
      flash.now[:error] = "Failed to create Barcode Item."
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

  # Only names that are real scopes on BarcodeItem. `class_filter` calls `public_send(key, value)`
  # for each of these, so a key that is not a scope raises -- and this list used to carry four
  # that are not: less_than_quantity, greater_than_quantity, equal_to_quantity and base_item_id.
  # Harmless only for as long as nothing called `class_filter`, which nothing did.
  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:barcodeable_id)
  end

  def load_barcode_item
    @barcode_item = BarcodeItem.find(params[:id])
  end
end
