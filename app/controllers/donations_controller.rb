class DonationsController < ApplicationController
  # We load the resources in before_filters so that they are not re-loaded
  # by Cancan, which won't use the correct methods.
  #before_filter :simple_load, only: [:track, :remove_item, :edit, :update, :destroy]
  #before_filter :eager_load_single, only: [:show]
  #before_filter :load_collection, only: [:index]
  #before_filter :load_new, only: [:new]

  # Cancan authorization
  #load_and_authorize_resource

  # TODO - needs to be able to handle barcodes too
  def add_item
    @donation = current_organization.donations.find(params[:id])
    if (donation_item_params.has_key?(:barcode_id))
      @donation.track_from_barcode(Barcode.find(donation_item_params[:barcode_id]).to_h)
    else
      @donation.track(donation_item_params[:item_id], donation_item_params[:quantity])
    end
  end

  def remove_item
    @donation = current_organization.donations.find(params[:id])
    @donation.remove(donation_item_params[:item_id])
  end

  def index
    @donations = current_organization.donations
                                      .includes(:line_items, :storage_location, :dropoff_location)
                                      .order(created_at: :desc)
  end

  def scale
    @donation = Donation.new(issued_at: Date.today)
    @donation.line_items.build
    @storage_locations = current_organization.storage_locations
    @dropoff_locations = current_organization.dropoff_locations
    @diaper_drive_participants = current_organization.diaper_drive_participants
    @items = current_organization.items.alphabetized
  end

  def create
    @donation = Donation.new(donation_params.merge(organization: current_organization))
    if (@donation.save)
      @donation.storage_location.intake! @donation
      redirect_to donations_path
    else
      @storage_locations = current_organization.storage_locations
      @dropoff_locations = current_organization.dropoff_locations
      @diaper_drive_participants = current_organization.diaper_drive_participants
      @items = current_organization.items.alphabetized
      @donation.line_items.build if @donation.line_items.count == 0
      flash[:notice] = "There was an error starting this donation, try again?"
      Rails.logger.info "ERROR: #{@donation.errors}"
      render action: :new
    end
  end

  def new
    @donation = Donation.new(issued_at: Date.today)
    @donation.line_items.build
    @storage_locations = current_organization.storage_locations
    @dropoff_locations = current_organization.dropoff_locations
    @diaper_drive_participants = current_organization.diaper_drive_participants
    @items = current_organization.items.alphabetized
  end

  def edit
    @donation = Donation.find(params[:id])
    @donation.line_items.build
    @storage_locations = current_organization.storage_locations
    @dropoff_locations = current_organization.dropoff_locations
    @diaper_drive_participants = current_organization.diaper_drive_participants
  end

  def show
    @donation = Donation.includes(:line_items).find(params[:id])
    @line_items = @donation.line_items
  end

  def update
    @donation = Donation.find(params[:id])
    @donation.update_attributes(donation_params)
    redirect_to(donation_path(@donation))
  end

  def destroy
    @donation = current_organization.donations.includes(:line_items, storage_location: :inventory_items).find(params[:id])
    @donation.destroy
    redirect_to donations_path
  end

private
  def donation_params
    params = strip_unnecessary_params
    params = compact_line_items
    params.require(:donation).permit(:source, :comment, :storage_location_id, :issued_at, :dropoff_location_id, :diaper_drive_participant_id, line_items_attributes: [:id, :item_id, :quantity, :_destroy]).merge(organization: current_organization)

  end

  def donation_item_params
    params.require(:donation).permit(:barcode_id, :item_id, :quantity)
  end

  # Omits dropoff_location_id or diaper_drive_participant_id if those aren't selected as source
  def strip_unnecessary_params
    params[:donation].delete(:dropoff_location_id) unless params[:donation][:source] == Donation::SOURCES[:dropoff]
    params[:donation].delete(:diaper_drive_participant_id) unless params[:donation][:source] == Donation::SOURCES[:diaper_drive]
    params
  end

  # If line_items have submitted with empty rows, clear those out first.
  def compact_line_items
    return params unless params[:donation].has_key?(:line_item_attributes)
    params[:donation][:line_items_attributes].delete_if { |row, data| data["quantity"].blank? && data["item_id"].blank? }
    params
  end
end
