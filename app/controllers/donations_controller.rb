class DonationsController < ApplicationController
  # We load the resources in before_filters so that they are not re-loaded
  # by Cancan, which won't use the correct methods.
  #before_filter :simple_load, only: [:track, :remove_item, :edit, :update, :destroy]
  #before_filter :eager_load_single, only: [:show]
  #before_filter :load_collection, only: [:index]
  #before_filter :load_new, only: [:new]

  # Cancan authorization
  #load_and_authorize_resource

  skip_before_action :verify_authenticity_token, only: [:scale_intake, :scale]
  skip_before_action :authenticate_user!, only: [:scale_intake, :scale]
  skip_before_action :authorize_user, only: [:scale_intake, :scale]

#  def add_item
#    @donation = current_organization.donations.find(params[:id])
#    if (donation_item_params.has_key?(:barcode_id))
#      donation_item_params[:item_id] = BarcodeItem.find!(donation_item_params[:barcode_id]).item_id
#    end
#    @donation.track(donation_item_params[:item_id], donation_item_params[:quantity])
#  end

#  def remove_item
#    @donation = current_organization.donations.find(params[:id])
#    @donation.remove(donation_item_params[:item_id])
#  end

  def index
    @donations = current_organization.donations
                                      .includes(:line_items, :storage_location, :dropoff_location, :diaper_drive_participant)
                                      .order(created_at: :desc)
                                      .filter(filter_params)
    # Are these going to be inefficient with large datasets?
    # Using the @donations allows drilling down instead of always starting with the total dataset
    @storage_locations = @donations.collect { |d| d.storage_location }.compact.uniq
    @selected_storage_location = filter_params[:at_storage_location]
    @sources = @donations.collect { |d| d.source }.uniq
    @selected_source = filter_params[:by_source]
    @dropoff_locations = @donations.collect { |d| d.dropoff_location }.compact.uniq
    @selected_dropoff_location = filter_params[:from_dropoff_location]
    @diaper_drives = @donations.collect { |d| next unless d.source ==  Donation::SOURCES[:diaper_drive]; d.diaper_drive_participant }.compact.uniq
    @selected_diaper_drive = filter_params[:by_diaper_drive_participant]
  end

  def scale
    @donation = Donation.new(issued_at: Date.today)
    @donation.line_items.build
    load_form_collections
  end

  def scale_intake
    @donation = Donation.create( organization: current_organization,
                                 source: "Misc. Donation",
                                 storage_location_id: current_organization.intake_location,
                                 issued_at: Date.today,
                                 line_items_attributes:{"0"=>{"item_id"=>params["diaper_type"],
                                                              "quantity"=>params["number_of_diapers"],
                                                              "_destroy"=>"false"}}
      )
    render status: 200, json: @donation.to_json
  end

  def create
    @donation = Donation.new(donation_params.merge(organization: current_organization))
    if (@donation.save)
      @donation.storage_location.intake! @donation
      redirect_to donations_path
    else
      load_form_collections
      @donation.line_items.build if @donation.line_items.count == 0
      flash[:alert] = "There was an error starting this donation, try again?"
      Rails.logger.info "ERROR: #{@donation.errors}"
      render action: :new
    end
  end

  def new
    @donation = Donation.new(issued_at: Date.today)
    @donation.line_items.build
    load_form_collections
  end

  def edit
    @donation = Donation.find(params[:id])
    @donation.line_items.build
    load_form_collections
  end

  def show
    @donation = Donation.includes(:line_items).find(params[:id])
    @line_items = @donation.line_items
  end

  def update
    @donation = Donation.find(params[:id])
    @donation.update_attributes(donation_params)
    redirect_to donations_path
  end

  def destroy
    @donation = current_organization.donations.includes(:line_items, storage_location: :inventory_items).find(params[:id])
    @donation.destroy
    redirect_to donations_path
  end

private
  
  def load_form_collections
    @storage_locations = current_organization.storage_locations
    @dropoff_locations = current_organization.dropoff_locations
    @diaper_drive_participants = current_organization.diaper_drive_participants
    @items = current_organization.items.alphabetized
  end

  def donation_params
    params = strip_unnecessary_params
    params = compact_line_items
    params.require(:donation).permit(:source, :comment, :storage_location_id, :issued_at, :dropoff_location_id, :diaper_drive_participant_id, line_items_attributes: [:id, :item_id, :quantity, :_destroy]).merge(organization: current_organization)

  end

  def donation_item_params
    params.require(:donation).permit(:barcode_id, :item_id, :quantity)
  end

  def filter_params
    return {} unless params.has_key?(:filters)
    params.require(:filters).slice(:at_storage_location, :by_source, :from_dropoff_location, :by_diaper_drive_participant)
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
