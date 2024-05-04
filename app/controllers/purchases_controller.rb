# Provides full CRUD for Purchases, which are a way for Diaperbanks to track inventory that they purchase from vendors
class PurchasesController < ApplicationController
  before_action :authorize_admin, only: [:destroy]

  def index
    setup_date_range_picker
    @purchases = current_organization.purchases
                                     .includes(:storage_location, :vendor, line_items: [:item])
                                     .order(created_at: :desc)
                                     .class_filter(filter_params)
                                     .during(helpers.selected_range)

    @paginated_purchases = @purchases.page(params[:page])
    # Are these going to be inefficient with large datasets?
    # Using the @purchases allows drilling down instead of always starting with the total dataset
    @purchases_quantity = @purchases.collect(&:total_quantity).sum
    @paginated_purchases_quantity = @paginated_purchases.collect(&:total_quantity).sum
    @total_value_all_purchases = @purchases.sum(&:amount_spent_in_cents)
    @storage_locations = current_organization.storage_locations.active_locations
    @selected_storage_location = filter_params[:at_storage_location]
    @vendors = current_organization.vendors.sort_by { |vendor| vendor.business_name.downcase }
    @selected_vendor = filter_params[:from_vendor]

    respond_to do |format|
      format.html
      #  format.csv { send_data Purchase.generate_csv(@purchases), filename: "Purchases-#{Time.zone.today}.csv" }
      format.csv do
        send_data Exports::ExportPurchasesCSVService.new(purchase_ids: @purchases.map(&:id)).generate_csv, filename: "Purchases-#{Time.zone.today}.csv"
      end
    end
  end

  def create
    @purchase = current_organization.purchases.new(purchase_params)
    begin
      PurchaseCreateService.call(@purchase)
      flash[:notice] = "New Purchase logged!"
      redirect_to purchases_path
    rescue => e
      load_form_collections
      @purchase.line_items.build if @purchase.line_items.count.zero?
      flash[:error] = "Failed to create purchase due to:\n#{e.message}"
      Rails.logger.error "[!] PurchasesController#create ERROR: #{e.message}"
      render action: :new
    end
  end

  def new
    @purchase = current_organization.purchases.new(issued_at: Time.zone.today)
    @purchase.line_items.build
    load_form_collections
  end

  def edit
    @purchase = current_organization.purchases.find(params[:id])
    @purchase.line_items.build
    @audit_performed_and_finalized = Audit.finalized_since?(@purchase, @purchase.storage_location_id)

    load_form_collections
  end

  def show
    @purchase = current_organization.purchases.includes(:line_items).find(params[:id])
    @line_items = @purchase.line_items
  end

  def update
    @purchase = current_organization.purchases.find(params[:id])
    ItemizableUpdateService.call(itemizable: @purchase,
      params: purchase_params,
      type: :increase,
      event_class: PurchaseEvent)
    redirect_to purchases_path
  rescue => e
    load_form_collections
    flash[:alert] = "Error updating purchase: #{e.message}"
    render "edit"
  end

  def destroy
    purchase = current_organization.purchases.find(params[:id])
    PurchaseDestroyService.call(purchase)

    flash[:notice] = "Purchase #{params[:id]} has been removed!"
    redirect_to purchases_path
  end

  private

  def load_form_collections
    @storage_locations = current_organization.storage_locations.active_locations.alphabetized
    @items = current_organization.items.active.alphabetized
    @vendors = current_organization.vendors.alphabetized
  end

  def purchase_params
    params = compact_line_items
    params.require(:purchase).permit(:comment, :amount_spent, :purchased_from,
      :amount_spent_on_diapers, :amount_spent_on_adult_incontinence, :amount_spent_on_period_supplies,
      :amount_spent_on_other,
      :storage_location_id, :issued_at, :vendor_id,
      line_items_attributes: %i(id item_id quantity _destroy))
      .merge(organization: current_organization)
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:at_storage_location, :by_source, :from_vendor)
  end

  # If line_items have submitted with empty rows, clear those out first.
  def compact_line_items
    return params unless params[:purchase].key?(:line_item_attributes)

    params[:purchase][:line_items_attributes].delete_if { |_row, data| data["quantity"].blank? && data["item_id"].blank? }
    params
  end

  def total_value(purchases)
    total_value_all_purchases = 0
    purchases.each do |purchase|
      total_value_all_purchases += purchase.value_per_itemizable
    end
    total_value_all_purchases
  end
end
