class KitsController < ApplicationController
  def index
    @kits = current_organization.kits.class_filter(filter_params)
    @base_items = current_organization.items.alphabetized
    @selected_item = filter_params[:by_partner_key]
    @include_inactive = params[:include_inactive]
    unless params[:include_inactive]
      @kits = @kits.active
    end
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

  def quantity
    @kit = Kit.find(params[:id])
    @storage_locations = current_organization.storage_locations
    @item_inventories = @kit.item.inventory_items

    load_form_collections
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

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:by_partner_key, :include_inactive_items)
  end
end
