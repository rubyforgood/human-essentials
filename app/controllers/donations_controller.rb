# Provides CRUD+ for Donations, which are digital representations of one of the ways Diaperbanks take in new inventory
class DonationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i(scale_intake scale)
  skip_before_action :authenticate_user!, only: %i(scale_intake scale)
  skip_before_action :authorize_user, only: %i(scale_intake scale)

  def index
    @donations = current_organization.donations
                                     .includes(:line_items, :storage_location, :donation_site, :diaper_drive_participant, :manufacturer)
                                     .order(created_at: :desc)
                                     .class_filter(filter_params)
    # Are these going to be inefficient with large datasets?
    # Using the @donations allows drilling down instead of always starting with the total dataset
    @donations_quantity = @donations.collect(&:total_quantity).sum
    @total_value_all_donations = total_value(@donations)
    @storage_locations = @donations.collect(&:storage_location).compact.uniq.sort
    @selected_storage_location = filter_params[:at_storage_location]
    @sources = @donations.collect(&:source).uniq.sort
    @selected_source = filter_params[:by_source]
    @donation_sites = @donations.collect(&:donation_site).compact.uniq.sort_by { |site| site.name.downcase }
    @selected_donation_site = filter_params[:from_donation_site]
    @diaper_drives = @donations.collect do |d|
      d.source == Donation::SOURCES[:diaper_drive] ? d.diaper_drive_participant : nil
    end.compact.uniq.sort
    @selected_diaper_drive = filter_params[:by_diaper_drive_participant]
    @manufacturers = @donations.collect(&:manufacturer).compact.uniq.sort
    @selected_manufacturer = filter_params[:from_manufacturer]

    @selected_date = date_filter
  end

  def scale
    @donation = Donation.new(issued_at: Time.zone.today)
    @donation.line_items.build
    load_form_collections
  end

  def scale_intake
    @donation = Donation.create(organization: current_organization,
                                source: "Misc. Donation",
                                storage_location_id: current_organization.intake_location,
                                issued_at: Time.zone.today,
                                line_items_attributes: { "0" => { "item_id" => params["diaper_type"],
                                                                  "quantity" => params["number_of_diapers"],
                                                                  "_destroy" => "false" } })
    @donation.storage_location.increase_inventory @donation
    render status: :ok, json: @donation.to_json
  end

  def create
    @donation = current_organization.donations.new(donation_params)
    if @donation.save
      @donation.storage_location.increase_inventory @donation
      redirect_to donations_path
    else
      load_form_collections
      @donation.line_items.build if @donation.line_items.count.zero?
      flash[:error] = "There was an error starting this donation, try again?"
      Rails.logger.error "[!] DonationsController#create Error: #{@donation.errors}"
      render action: :new
    end
  end

  def new
    @donation = Donation.new(issued_at: Time.zone.today)
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
    if @donation.replace_increase!(donation_params)
      redirect_to donations_path
    else
      render "edit"
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      donation = current_organization.donations.find(params[:id])
      donation.storage_location.decrease_inventory(donation)
      donation.destroy!
    end

    flash[:notice] = "Donation #{params[:id]} has been removed!"
    redirect_to donations_path
  end

  private

  def load_form_collections
    @storage_locations = current_organization.storage_locations.alphabetized
    @donation_sites = current_organization.donation_sites.alphabetized
    @diaper_drive_participants = current_organization.diaper_drive_participants.alphabetized
    @manufacturers = current_organization.manufacturers.alphabetized
    @items = current_organization.items.active.alphabetized
  end

  def donation_params
    strip_unnecessary_params
    params = compact_line_items
    params.require(:donation).permit(:source, :comment, :storage_location_id, :money_raised, :issued_at, :donation_site_id, :diaper_drive_participant_id, :manufacturer_id, line_items_attributes: %i(id item_id quantity _destroy)).merge(organization: current_organization)
  end

  def donation_item_params
    params.require(:donation).permit(:barcode_id, :item_id, :quantity)
  end

  def filter_params
    return {} unless params.key?(:filters)

    fp = params.require(:filters).slice(:at_storage_location, :by_source, :from_donation_site, :by_diaper_drive_participant, :from_manufacturer)
    fp.merge(by_issued_at: date_filter)
  end

  def date_filter
    return nil unless params.key?(:date_filters)

    date_params = params.require(:date_filters)
    if date_params["issued_at(1i)"] == "" || date_params["issued_at(2i)"].to_i == ""
      return nil
    end

    Date.new(date_params["issued_at(1i)"].to_i, date_params["issued_at(2i)"].to_i, date_params["issued_at(3i)"].to_i)
  end

  # Omits donation_site_id or diaper_drive_participant_id if those aren't selected as source
  def strip_unnecessary_params
    params[:donation].delete(:donation_site_id) unless params[:donation][:source] == Donation::SOURCES[:donation_site]
    params[:donation].delete(:manufacturer_id) unless params[:donation][:source] == Donation::SOURCES[:manufacturer]
    params[:donation].delete(:diaper_drive_participant_id) unless params[:donation][:source] == Donation::SOURCES[:diaper_drive]
    params
  end

  # If line_items have submitted with empty rows, clear those out first.
  def compact_line_items
    return params unless params[:donation].key?(:line_item_attributes)

    params[:donation][:line_items_attributes].delete_if { |_row, data| data["quantity"].blank? && data["item_id"].blank? }
    params
  end

  def total_value(donations)
    total_value_all_donations = 0
    donations.each do |donation|
      total_value_all_donations += donation.value_per_itemizable
    end
    total_value_all_donations
  end
end
