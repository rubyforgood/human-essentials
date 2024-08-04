class ProductDrivesController < ApplicationController
  include Importable
  before_action :set_product_drive, only: [:show, :edit, :update, :destroy]

  def index
    setup_date_range_picker
    @product_drives = current_organization
                     .product_drives
                     .includes(donations: {line_items: :item})
                     .class_filter(filter_params)
                     .within_date_range(@selected_date_range)
                     .order(start_date: :desc)
    # to be used in the name filter to sort product drives in alpha order
    @product_drives_alphabetical = @product_drives.sort_by { |pd| pd.name.downcase }
    @item_categories = current_organization.item_categories
    @selected_name_filter = filter_params[:by_name]
    @selected_item_category = filter_params[:by_item_category_id]

    respond_to do |format|
      format.html
      format.csv do
        send_data Exports::ExportProductDrivesCSVService.new(
          @product_drives,
          current_organization,
          helpers.selected_range
        ).generate_csv, filename: "Product-Drives-#{Time.zone.today}.csv"
      end
    end
  end

  # GET /product_drives/1
  # GET /product_drives/1.json

  def create
    @product_drive = current_organization.product_drives.new(product_drive_params.merge(organization: current_organization))
    respond_to do |format|
      if @product_drive.save
        format.html { redirect_to product_drives_path, notice: "New product drive added!" }
        format.js
      else
        flash[:error] = "Something didn't work quite right -- try again?"
        format.html { render action: :new }
        format.js { render template: "product_drives/new_modal" }
      end
    end
  end

  def new
    @product_drive = current_organization.product_drives.new
    if request.xhr?
      respond_to do |format|
        format.js { render template: "product_drives/new_modal" }
      end
    end
  end

  def edit
    @product_drive = current_organization.product_drives.find(params[:id])
  end

  def show
    @selected_name_filter = filter_params[:by_name]
    @selected_item_category = filter_params[:by_item_category_id]
    @product_drive = current_organization.product_drives.includes(:donations).find(params[:id])
  end

  def update
    @product_drive = current_organization.product_drives.find(params[:id])
    if @product_drive.update(product_drive_params)
      redirect_to product_drives_path, notice: "#{@product_drive.name} updated!"

    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    current_organization.product_drives.find(params[:id]).destroy
    respond_to do |format|
      format.html { redirect_to product_drives_url, notice: 'Product drive was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product_drive
    @product_drive_info = ProductDrive.find(params[:id])
  end

  def product_drive_params
    params.require(:product_drive)
          .permit(:name, :start_date, :end_date, :virtual)
  end

  def date_range_filter
    return '' unless params.key?(:filters)

    params.require(:filters)[:date_range]
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_name, :by_item_category_id)
  end
end
