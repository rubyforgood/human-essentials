class DonationsController < ApplicationController
  # We load the resources in before_filters so that they are not re-loaded
  # by Cancan, which won't use the correct methods.
  before_filter :simple_load, only: [:track, :remove_item, :complete, :edit, :update, :destroy]
  before_filter :eager_load_single, only: [:show]
  before_filter :load_collection, only: [:index]
  before_filter :load_new, only: [:new]

  # Cancan authorization
  load_and_authorize_resource

  # TODO - needs to be able to handle barcodes too
  def track
#    @donation = current_organization.donations.find(params[:id])
    if (donation_item_params.has_key?(:barcode_id))
      @donation.track_from_barcode(Barcode.find(donation_item_params[:barcode_id]).to_line_item)
    else
      @donation.track(donation_item_params[:item_id], donation_item_params[:quantity])
    end
  end

  def remove_item
 #   @donation = current_organization.donations.find(params[:id])
    @donation.remove(donation_item_params[:item_id])
  end

  def complete
 #   @donation = current_organization.donations.find(params[:id])
    @donation.complete
    redirect_to donations_path, notice: "Completed!"
  end

  def index
#   @donations = Donation.includes(:line_items, :storage_location, :dropoff_location)
    @completed = @donations.completed
    @incomplete = @donations.incomplete
  end

  def create
#    @donation = Donation.new(donation_params.merge(organization: current_organization))
    if (@donation.save)
      redirect_to(edit_donation_path(@donation))
    else
      @storage_locations = StorageLocation.all
      @dropoff_locations = DropoffLocation.all
      flash[:notice] = "There was an error starting this donation, try again?"
      render action: :new
    end
  end

  def new
#    @donation = Donation.new
    @storage_locations = StorageLocation.all
    @dropoff_locations = DropoffLocation.all

  end

  def edit
#   @donation = current_organization.donations.find(params[:id])    
    @storage_locations = StorageLocation.all
    @dropoff_locations = DropoffLocation.all

  end

  def show
#    @donation = Donation.includes(:line_items).find(params[:id])
    @line_items = @donation.line_items
  end

  def update
#    @donation = Donation.find(params[:id])
    @donation.update_attributes(donation_params)
    redirect_to(donation_path(@donation))
  end

  def destroy
#   @donation = current_organization.donations.find(params[:id])
    @donation.destroy
    redirect_to donations_path
  end

private
  def load_new
    @donation = current_organization.donations.build
  end

  def eager_load_single
    @donation = current_organization.donations.includes(:line_items).find(params[:id])
  end

  def simple_load
    @donation = current_organization.donations.find(params[:id])
  end

  def load_collection
    @donations = Donation.includes(:line_items, :storage_location, :dropoff_location)
  end

  def donation_params
    params.require(:donation).permit(:source, :storage_location_id, :dropoff_location_id).merge(organization: current_organization)
  end

  def donation_item_params
    params.require(:donation).permit(:barcode_id, :item_id, :quantity)
  end
end

