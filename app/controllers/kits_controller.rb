class KitsController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def show
    redirect_to allocations_kit_path
  end

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
      load_form_collections
      @kit = current_organization.kits.new(kit_params)

      # The service reports its errors separately from the record, and this used to flatten them
      # into a flash sentence and render a Kit with none -- so every field came back clean and
      # the only sign of trouble was a line at the top. Copying them onto the record the form
      # renders is what puts each message beside its own field.
      #
      # Built from `current_organization.kits.new(kit_params)` rather than the `Kit.new` +
      # `kit_item` pair this used: main made Kit an STI subclass of Item, so the line items hang
      # off the kit itself and there is no KitItem to construct. Errors are added *after* the
      # record is built, because building it is what would clear them.
      kit_creation.errors.each { |error| @kit.errors.add(error.attribute, error.message) }
      @kit.line_items.build if @kit.line_items.empty?

      render :new
    end
  end

  def deactivate
    @kit = current_organization.kits.find(params[:id])
    # The action is offered even when it cannot succeed, so this is where the reason is given --
    # design.md, an unavailable action is attempted and answered rather than greyed out. `Kit` is
    # an `Item` by STI, so `deactivate!` already raises a sentence written to be read in a flash.
    # `reactivate` below has always worked this way; this is the same shape.
    begin
      @kit.deactivate!
    rescue => e
      redirect_back_or_to(dashboard_path, alert: e.message)
      return
    end
    redirect_back_or_to(dashboard_path, notice: "Kit has been deactivated!")
  end

  def reactivate
    @kit = current_organization.kits.find(params[:id])
    if @kit.can_reactivate?
      @kit.reactivate
      redirect_back_or_to(dashboard_path, notice: "Kit has been reactivated!")
    else
      redirect_back_or_to(dashboard_path, alert: "Cannot reactivate kit - it has inactive items! Please reactivate the items first.")
    end
  end

  def allocations
    @kit = current_organization.kits.find(params[:id])
    @storage_locations = current_organization.storage_locations.active
    @inventory = View::Inventory.new(current_organization.id)

    load_form_collections
  end

  def allocate
    @kit = current_organization.kits.find(params[:id])
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
    ).to_h
  end

  def kit_adjustment_params
    params.require(:kit_adjustment).permit(:storage_location_id, :change_by)
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:by_name)
  end

  # main's `formatted_error_message` is deliberately not merged. It existed only to build the flash
  # sentence that `create` no longer writes: the service's errors go onto the record now, so the
  # summary above the form and the field-level messages render them. Nothing else called it.
end
