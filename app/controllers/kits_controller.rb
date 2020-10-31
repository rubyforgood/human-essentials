class KitsController < ApplicationController
  def index
    @kits = current_organization.kits.includes(line_items: :item, inventory_items: :storage_location).class_filter(filter_params)
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
      flash[:error] = kit_creation.errors
                                  .full_messages
                                  .map(&:humanize)
                                  .join(", ")

      load_form_collections

      @kit ||= Kit.new
      @kit.line_items.build

      render :new
    end
  end

  def allocations
    @kit = Kit.find(params[:id])
    @storage_locations = current_organization.storage_locations
    @item_inventories = @kit.item.inventory_items

    load_form_collections
  end

  def allocate
    @kit = Kit.find(params[:id])
    @storage_location = current_organization.storage_locations.find(kit_adjustment_params[:storage_location_id])
    @change_by = kit_adjustment_params[:change_by].to_i

    if @change_by.positive?
      service = AllocateKitInventoryService.new(kit: @kit, storage_location: @storage_location, increase_by: @change_by)
      service.allocate
      flash[:error] = service.error if service.error
    elsif @change_by.negative?
      service = DeallocateKitInventoryService.new(kit: @kit, storage_location: @storage_location, decrease_by: @change_by.abs)
      service.deallocate
      flash[:error] = service.error if service.error
    end

    if service.error
      flash[:error] = service.error
    else
      flash[:notice] = "#{@kit.name} at #{@storage_location.name} quantity has changed by #{@change_by}"
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
end
