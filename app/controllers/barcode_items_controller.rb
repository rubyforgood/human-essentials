# Provides full CRUD+ for Barcode Items. These barcode items are all associated with regular Items. The one
# anomaly here is the :find action, which has some special logic built-in to it, see the comments below.
class BarcodeItemsController < ApplicationController
  def index
    @items = Item.gather_items(current_organization, @global)
    @base_items = BaseItem.alphabetized
    @selected_barcodeable_id = filter_params[:barcodeable_id]
    @selected_partner_key = filter_params[:by_item_partner_key]
    @selected_barcode_id = filter_params[:by_value]
    @barcode_items = current_organization.barcode_items.class_filter(filter_params)
    @selected_item = filter_params[:barcodeable_id]
    @selected_partner_key = filter_params[:by_item_partner_key]

    respond_to do |format|
      format.html
      format.csv { send_data BarcodeItem.generate_csv(@barcode_items), filename: "BarcodeItems-#{Time.zone.today}.csv" }
    end
  end

  def create
    @barcode_item = current_organization.barcode_items.new(barcode_item_params)
    if @barcode_item.save
      msg = "New barcode added to your private set!"
      respond_to do |format|
        format.json { render json: @barcode_item.to_json }
        format.js
        format.html { redirect_to barcode_items_path, notice: msg }
      end
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @barcode_item = current_organization.barcode_items.new
    @items = current_organization.items.alphabetized
  end

  def edit
    @barcode_item = current_organization.barcode_items.includes(:barcodeable).find(params[:id])
    @items = current_organization.items.alphabetized
  end

  def show
    @barcode_item = current_organization.barcode_items.includes(:barcodeable).find(params[:id])
  end

  def font
    send_file(
      "#{Rails.root}/public/fonts/LibreBarcode128-Regular.ttf",
      filename: "LibreBarcode128-Regular.ttf",
      type: "application/ttf"
    )
  end

  def find
    # First, we do a naive lookup
    @barcode_item = current_organization.barcode_items.all.find_by!(value: barcode_item_params[:value])
    # Depending on whether or not the result is solely a global barcode, we may need additional queries
    # Global barcodes don't explicitly map to organization items, so we can do a lookup to clarify that
    if @barcode_item.global?
      # So in this case, we need to do an item lookup. #593 clarifies that we should fall through to the
      # *oldest* item that the organization has that matches this base item type.
      base_item = @barcode_item.barcodeable
      @item = current_organization.items.by_base_item(base_item).order("created_at ASC").first
    else
      # It was a local barcode_item, which maps directly to a known org item. We're set!
      @item = @barcode_item.item
    end
    respond_to do |format|
      format.json { render json: { barcode_item: @barcode_item, item: @item }.to_json }
    end
  end

  def update
    @barcode_item = current_organization.barcode_items.find(params[:id])
    if @barcode_item.update(barcode_item_params)
      redirect_to barcode_items_path, notice: "Barcode updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    begin
      barcode = current_organization.barcode_items.find(params[:id])
      raise if barcode.nil? || barcode.global?

      barcode.destroy
    rescue StandardError
      flash[:error] = "Sorry, you don't have permission to delete this barcode."
    end
    redirect_to barcode_items_path
  end

  private

  def barcode_item_params
    params.require(:barcode_item).permit(:value, :barcodeable_id, :quantity).merge(organization_id: current_organization.id)
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:barcodeable_id, :by_item_partner_key, :by_value)
  end
end
