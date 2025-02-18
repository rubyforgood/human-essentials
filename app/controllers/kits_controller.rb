class KitsController < ApplicationController
  def index
    @kits = current_organization.kits.includes(line_items: :item).class_filter(filter_params)
    @inventory = View::Inventory.new(current_organization.id)
    unless params[:include_inactive_items]
      @kits = @kits.active
    end
    @selected_filter_name = filter_params[:by_name]
  end

  def new
    load_form_collections

    @kit = current_organization.kits.new
    @kit.line_items.build
  end

  def create
    kit_creation = KitCreateService.new(organization_id: current_organization.id, kit_params: kit_params)
    kit_creation.call

    if kit_creation.errors.none?
      flash[:notice] = "Kit created successfully"
      redirect_to kits_path
    else
      flash.now[:error] = kit_creation.errors
        .map { |error| formatted_error_message(error) }
        .join(", ")

      @kit = Kit.new(kit_params)
      load_form_collections
      @kit.line_items.build if @kit.line_items.empty?

      render :new
    end
  end

  def deactivate
    @kit = Kit.find(params[:id])
    @kit.deactivate
    redirect_back(fallback_location: dashboard_path, notice: "Kit has been deactivated!")
  end

  def reactivate
    @kit = Kit.find(params[:id])
    if @kit.can_reactivate?
      @kit.reactivate
      redirect_back(fallback_location: dashboard_path, notice: "Kit has been reactivated!")
    else
      redirect_back(fallback_location: dashboard_path, alert: "Cannot reactivate kit - it has inactive items! Please reactivate the items first.")
    end
  end

  def allocations
    @kit = Kit.find(params[:id])
    @storage_locations = current_organization.storage_locations.active
    @inventory = View::Inventory.new(current_organization.id)

    load_form_collections
  end

  def allocate
    @kit = Kit.find(params[:id])
    @storage_location = current_organization.storage_locations.active.find(kit_adjustment_params[:storage_location_id])
    @change_by = kit_adjustment_params[:change_by].to_i
    begin
      if @change_by.positive?
        KitAllocateEvent.publish(@kit, @storage_location.id, @change_by)
      else
        KitDeallocateEvent.publish(@kit, @storage_location.id, -@change_by)
      end
    rescue => e
      flash[:error] = e.message
    end

    redirect_to allocations_kit_path(id: @kit.id)
  end

  private

  def load_form_collections
    @items = current_organization.items.active.alphabetized
  end

  def kit_params
    params.require(:kit).permit(
      :name,
      :visible_to_partners,
      :value_in_dollars,
      line_items_attributes: [:item_id, :quantity, :_destroy]
    )
  end

  def kit_adjustment_params
    params.require(:kit_adjustment).permit(:storage_location_id, :change_by)
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:by_name)
  end

  def formatted_error_message(error)
    if error.attribute.to_s == "inventory"
      "Sorry, we weren't able to save the kit. Validation failed: #{error.message}"
    else
      error.full_message.humanize
    end
  end
end
