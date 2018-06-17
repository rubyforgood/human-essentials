class PurchasesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i(scale_intake scale)
  skip_before_action :authenticate_user!, only: %i(scale_intake scale)
  skip_before_action :authorize_user, only: %i(scale_intake scale)

  def index
    @purchases = current_organization.purchases
                                     .includes(:line_items, :storage_location)
                                     .order(created_at: :desc)
                                     .filter(filter_params)
    # Are these going to be inefficient with large datasets?
    # Using the @purchases allows drilling down instead of always starting with the total dataset
    @storage_locations = @purchases.collect(&:storage_location).compact.uniq
    @selected_storage_location = filter_params[:at_storage_location]
  end

  def create
    @purchase = current_organization.purchases.new(purchase_params)
    if @purchase.save
      @purchase.storage_location.intake! @purchase
      redirect_to purchases_path
    else
      load_form_collections
      @purchase.line_items.build if @purchase.line_items.count == 0
      flash[:error] = "There was an error starting this purchase, try again?"
      Rails.logger.error "ERROR: #{@purchase.errors}"
      render action: :new
    end
  end

  def new
    @purchase = current_organization.purchases.new(issued_at: Date.today)
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
    @purchase.changed?
    previous_quantities = @purchase.line_items_quantities
    if @purchase.update(purchase_params)
      @purchase.storage_location.adjust_from_past!(@purchase, previous_quantities)
      redirect_to purchases_path
    else
      render "edit"
    end
  end

  def destroy
    @purchase = current_organization.purchases.includes(:line_items, storage_location: :inventory_items).find(params[:id])
    @purchase.destroy
    redirect_to purchases_path
  end

  private

  def load_form_collections
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
  end

  def purchase_params
    params = compact_line_items
    params.require(:purchase).permit(:comment, :amount_spent, :purchased_from, :storage_location_id, :issued_at, line_items_attributes: %i(id item_id quantity _destroy)).merge(organization: current_organization)
  end

  def filter_params
    return {} unless params.key?(:filters)
    params.require(:filters).slice(:at_storage_location, :by_source)
  end

  # If line_items have submitted with empty rows, clear those out first.
  def compact_line_items
    return params unless params[:purchase].key?(:line_item_attributes)
    params[:purchase][:line_items_attributes].delete_if { |_row, data| data["quantity"].blank? && data["item_id"].blank? }
    params
  end
end
