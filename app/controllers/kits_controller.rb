class KitsController < ApplicationController
  def new
    load_form_collections
    @kit = current_organization.kits.new
    @kit.line_items.build
  end

  def edit
  end

  def create
    @kit = current_organization.kits.new(kit_params)
    @kit.organization_id = current_organization.id
    if @kit.save
      flash[:notice] = "Kit created successfully"
      redirect_to items_path
    else
      flash[:error] = @kit.errors.full_messages.to_sentence
      load_form_collections
      render :new
    end
  end

  def update
  end

  private

  def load_form_collections
    @items = current_organization.items.active.alphabetized
    @storage_locations = current_organization.storage_locations
  end

  def kit_params
    params.require(:kit).permit(:name, line_items_attributes: [:item_id, :quantity, :_destroy])
  end
end
