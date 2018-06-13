class BarcodeItemsController < ApplicationController
  def index
    @global = filter_params[:include_global] || false
    @items = Item.gather_items(current_organization, @global)
    @barcode_items = if @global
                       current_organization.barcode_items.include_global(false) + BarcodeItem.where(global: true)
                     else
                       current_organization.barcode_items.include_global(false).filter(filter_params)
                     end
  end

  def create
    @barcode_item = current_organization.barcode_items.new(barcode_item_params)
    if @barcode_item.save
      msg = "New barcode added"
      msg += barcode_item_params[:global] == "true" ? " globally!" : " to your private set!"
      respond_to do |format|
        format.json { render json: @barcode_item.to_json }
        format.html { redirect_to barcode_items_path, notice: msg }
      end
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :new
    end
  end

  def new
    @barcode_item = current_organization.barcode_items.new
    @items = current_organization.items
  end

  def edit
    @barcode_item = current_organization.barcode_items.includes(:barcodeable).find(params[:id])
    @items = current_organization.items
  end

  def show
    @barcode_item = current_organization.barcode_items.includes(:barcodeable).find(params[:id])
  end

  def find
    @barcode_item = current_organization.barcode_items.includes(:barcodeable).find_by!(value: barcode_item_params[:value])
    respond_to do |format|
      format.json { render json: @barcode_item.to_json }
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
      # If the user is a superadmin, they can delete any Barcode
      if current_user.is_superadmin?
        barcode = BarcodeItem.find(params[:id])
      # Otherwise it has to be non-global in their organization
      else
        barcode = current_organization.barcode_items.find(params[:id])
        raise if barcode.nil? || barcode.global?
      end
      barcode.destroy
    rescue Exception => e
      flash[:error] = "Sorry, you don't have permission to delete this barcode."
    end
    redirect_to barcode_items_path
  end

  private

  def barcode_item_params
    params.require(:barcode_item).permit(:value, :barcodeable_id, :quantity, :global).merge(organization_id: current_organization.id)
  end

  def filter_params
    return {} unless params.key?(:filters)
    params.require(:filters).slice(:barcodeable_id, :less_than_quantity, :greater_than_quantity, :equal_to_quantity, :include_global, :canonical_item_id)
  end
end
