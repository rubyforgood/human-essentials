# Provides full CRUD for Purchases, which are a way for Diaperbanks to track inventory that they purchase from vendors
class PurchasesController < ApplicationController
  def index
    setup_date_range_picker
    @purchases = current_organization.purchases
                                     .includes(:line_items, :storage_location)
                                     .order(created_at: :desc)
                                     .class_filter(filter_params)
                                     .during(helpers.selected_range)

    @paginated_purchases = @purchases.page(params[:page])
    # Are these going to be inefficient with large datasets?
    # Using the @purchases allows drilling down instead of always starting with the total dataset
    @purchases_quantity = @purchases.collect(&:total_quantity).sum
    @paginated_purchases_quantity = @paginated_purchases.collect(&:total_quantity).sum
    @total_value_all_purchases = @purchases.sum(&:amount_spent_in_cents)
    @storage_locations = @purchases.collect(&:storage_location).compact.uniq
    @selected_storage_location = filter_params[:at_storage_location]
    @vendors = @purchases.collect(&:vendor).compact.uniq.sort_by { |vendor| vendor.business_name.downcase }
    @selected_vendor = filter_params[:from_vendor]
  end

  def create
    @purchase = current_organization.purchases.new(purchase_params)
    if @purchase.save
      @purchase.storage_location.increase_inventory @purchase
      flash[:notice] = "New Purchase logged!"
      redirect_to purchases_path
    else
      load_form_collections
      @purchase.line_items.build if @purchase.line_items.count.zero?
      flash[:error] = "There was an error starting this purchase, try again?"
      Rails.logger.error "[!] PurchasesController#create ERROR: #{@purchase.errors.full_messages}"
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
    load_form_collections
  end

  def show
    @purchase = current_organization.purchases.includes(:line_items).find(params[:id])
    @line_items = @purchase.line_items
  end

  def update
    @purchase = current_organization.purchases.find(params[:id])
    if @purchase.replace_increase!(purchase_params)
      redirect_to purchases_path
    else
      render "edit"
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      purchase = current_organization.purchases.find(params[:id])
      purchase.storage_location.decrease_inventory(purchase)
      purchase.destroy!
    end

    flash[:notice] = "Purchase #{params[:id]} has been removed!"
    redirect_to purchases_path
  end

  private

  def clean_purchase_amount_in_cents
    return nil unless params[:purchase][:amount_spent_in_cents]

    params[:purchase][:amount_spent_in_cents] = params[:purchase][:amount_spent_in_cents].gsub(/[$,.]/, "")
  end

  def clean_purchase_amount_in_dollars
    return nil unless params[:purchase][:amount_spent_in_dollars]

    params[:purchase][:amount_spent_in_cents] = params[:purchase][:amount_spent_in_dollars].gsub(/[$,]/, "").to_d * 100
  end

  def load_form_collections
    @storage_locations = current_organization.storage_locations.alphabetized
    @items = current_organization.items.active.alphabetized
    @vendors = current_organization.vendors.alphabetized
  end

  def purchase_params
    clean_purchase_amount_in_cents
    clean_purchase_amount_in_dollars
    params = compact_line_items
    params.require(:purchase).permit(:comment, :amount_spent_in_cents, :purchased_from, :storage_location_id, :issued_at, :vendor_id, line_items_attributes: %i(id item_id quantity _destroy)).merge(organization: current_organization)
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:at_storage_location, :by_source, :from_vendor)
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
