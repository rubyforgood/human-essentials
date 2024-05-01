# Provides partial CRUD for managing Transfers, which move inventory from one storage location to another
class TransfersController < ApplicationController
  def index
    setup_date_range_picker

    @transfers = current_organization.transfers
                                     .includes(:line_items)
                                     .includes(:from)
                                     .includes(:to)
                                     .class_filter(filter_params)
                                     .during(helpers.selected_range)
    @selected_from = filter_params[:from_location]
    @selected_to = filter_params[:to_location]
    @from_storage_locations = Transfer.storage_locations_transferred_from_in(current_organization)
    @to_storage_locations = Transfer.storage_locations_transferred_to_in(current_organization)
    respond_to do |format|
      format.html
      format.csv { send_data Transfer.generate_csv(@transfers), filename: "Transfers-#{Time.zone.today}.csv" }
    end
  end

  def create
    @transfer = current_organization.transfers.new(transfer_params)

    TransferCreateService.call(@transfer)
    redirect_to transfers_path, notice: "#{@transfer.line_items.total} items have been transferred from #{@transfer.from.name} to #{@transfer.to.name}!"
  rescue StandardError => e
    flash[:error] = e.message
    load_form_collections
    @transfer.line_items.build if @transfer.line_items.empty?
    render :new
  end

  def new
    @transfer = current_organization.transfers.new
    @transfer.line_items.build
    @storage_locations = current_organization.storage_locations.active_locations.alphabetized
    @items = current_organization.items.active.alphabetized
  end

  def show
    @transfer = current_organization.transfers.includes(:line_items).includes(:from).includes(:to).includes(:items).find(params[:id])
    @total = @transfer.line_items.total
    @line_items = @transfer.line_items.sorted
  end

  def destroy
    transfer_destroy_service = TransferDestroyService.new(transfer_id: params[:id])
    results = transfer_destroy_service.call

    if results.success?
      flash[:notice] = "Succesfully deleted Transfer ##{params[:id]}!"
    else
      flash[:error] = results.error.message
    end

    redirect_to transfers_path
  end

  private

  def load_form_collections
    @storage_locations = current_organization.storage_locations.active_locations.alphabetized
    @items = current_organization.items.alphabetized
  end

  def transfer_params
    params.require(:transfer).permit(:from_id, :to_id, :comment,
                                     line_items_attributes: %i(item_id quantity _destroy))
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:from_location, :to_location)
  end
end
