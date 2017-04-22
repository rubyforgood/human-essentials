class DonationsController < ApplicationController
  # TODO - needs to be able to handle barcodes too
  def track
    @donation = Donation.find(params[:id])
    if (donation_item_params.has_key?(:barcode_id))
      @donation.track_from_barcode(Barcode.find(donation_item_params[:barcode_id]).to_container)
    else
      @donation.track(donation_item_params[:item_id], donation_item_params[:quantity])
    end
  end

  def remove_item
    @donation = Donation.find(params[:id])
    @donation.remove(donation_item_params[:item_id])
  end

  def complete
    @donation = Donation.find(params[:id])
    @donation.complete
    redirect_to :back
  end

  def index
    @donations = Donation.all
  end

  def create
    @donation = Donation.create(donation_params)
    redirect_to(donation_path(@donation))
  end

  def new
    @donation = Donation.new
  end

  def edit
    @donation = Donation.find(params[:id])
  end

  def show
    @donation = Donation.find(params[:id])
  end

  def update
    @donation = Donation.find(params[:id])
    Donation.update_attributes(donation_update_params)
    redirect_to(donation_path(@donation))
  end

  def destroy
    Donation.find(params[:id]).destroy
    redirect_to donations_path
  end

private
  def donation_update_params
    params.require(:donation).permit(:source, :inventory_id)
  end

  def donation_item_params
    params.require(:donation).permit(:barcode_id, :item_id, :quantity)
  end
end

