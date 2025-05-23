# Provides CRUD+ for Donations, which are digital representations of one of the ways Diaperbanks take in new inventory
class DonationsController < ApplicationController
  before_action :authorize_admin, only: [:destroy]

  def print
    @donation = Donation.find(params[:id])
    respond_to do |format|
      format.any do
        pdf = DonationPdf.new(current_organization, @donation)
        send_data pdf.compute_and_render,
          filename: format("%s %s.pdf", @donation.source, sortable_date(@donation.created_at)),
          type: "application/pdf",
          disposition: "inline"
      end
    end
  end

  def index
    setup_date_range_picker

    @donations = current_organization.donations
                                     .includes(:storage_location, :donation_site, :product_drive, :product_drive_participant, :manufacturer, line_items: [:item])
                                     .order(created_at: :desc)
                                     .class_filter(filter_params)
                                     .during(helpers.selected_range)
    @paginated_donations = @donations.page(params[:page])

    @product_drives = current_organization.product_drives.alphabetized
    @product_drive_participants = current_organization.product_drive_participants.alphabetized

    # Are these going to be inefficient with large datasets?
    # Using the @donations allows drilling down instead of always starting with the total dataset
    @donations_quantity = @donations.collect(&:total_quantity).sum
    @paginated_donations_quantity = @paginated_donations.collect(&:total_quantity).sum
    @total_value_all_donations = total_value(@donations)
    @paginated_in_kind_value = total_value(@paginated_donations)
    @total_money_raised = total_money_raised(@donations)
    @storage_locations = @donations.filter_map { |donation| donation.storage_location if !donation.storage_location.discarded_at }.compact.uniq.sort
    @selected_storage_location = filter_params[:at_storage_location]
    @sources = @donations.collect(&:source).uniq.sort
    @selected_source = filter_params[:by_source]
    @donation_sites = @donations.collect(&:donation_site).compact.uniq.sort_by { |site| site.name.downcase }
    @selected_donation_site = filter_params[:from_donation_site]
    @selected_product_drive = filter_params[:by_product_drive]
    @selected_product_drive_participant = filter_params[:by_product_drive_participant]
    @manufacturers = @donations.collect(&:manufacturer).compact.uniq.sort
    @selected_manufacturer = filter_params[:from_manufacturer]

    respond_to do |format|
      format.html
      format.csv do
        send_data Exports::ExportDonationsCSVService.new(donation_ids: @donations.map(&:id), organization: current_organization).generate_csv, filename: "Donations-#{Time.zone.today}.csv"
      end
    end
  end

  def create
    @donation = current_organization.donations.new(donation_params)

    begin
      DonationCreateService.call(@donation)
      flash[:notice] = "Donation created and logged!"
      redirect_to donations_path
    rescue => e
      load_form_collections
      @donation.line_items.build if @donation.line_items.count.zero?
      flash.now[:error] = "There was an error starting this donation: #{e.message}"
      Rails.logger.error "[!] DonationsController#create Error: #{e.message}"
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
    @audit_performed_and_finalized = Audit.finalized_since?(@donation, @donation.storage_location_id)

    load_form_collections
  end

  def show
    @donation = Donation.includes(line_items: :item).find(params[:id])
    @line_items = @donation.line_items
  end

  def update
    @donation = Donation.find(params[:id])
    @original_source = @donation.source
    ItemizableUpdateService.call(itemizable: @donation,
      params: donation_params,
      event_class: DonationEvent)
    flash.clear
    flash[:notice] = "Donation updated!"
    redirect_to donations_path
  rescue => e
    flash.now[:alert] = "Error updating donation: #{e.message}"
    load_form_collections
    # calling new(donation_params) triggers a validation error if line_item quantity is invalid
    @previous_input = Donation.new(donation_params.except(:line_items_attributes))
    @previous_input.line_items.build(donation_params[:line_items_attributes].values)

    render "edit", status: :conflict
  end

  def destroy
    service = DonationDestroyService.new(organization_id: current_organization.id, donation_id: params[:id])
    service.call

    if service.success?
      flash[:notice] = "Donation #{params[:id]} has been removed!"
    else
      flash[:error] = "Donation #{params[:id]} failed to be removed because #{service.error}"
    end

    redirect_to donations_path
  end

  private

  def load_form_collections
    @storage_locations = current_organization.storage_locations.active.alphabetized
    @donation_sites = current_organization.donation_sites.active.alphabetized
    @product_drives = current_organization.product_drives.alphabetized
    @product_drive_participants = current_organization.product_drive_participants.alphabetized
    @manufacturers = current_organization.manufacturers.alphabetized
    @items = current_organization.items.active.alphabetized
  end

  def clean_donation_money_raised
    money_raised = params[:donation][:money_raised]
    params[:donation][:money_raised] = money_raised.gsub(/[$,.]/, "") if money_raised

    money_raised_in_dollars = params[:donation][:money_raised_in_dollars]
    params[:donation][:money_raised] = (money_raised_in_dollars.gsub(/[$,]/, "").to_d * 100).to_s if money_raised_in_dollars
  end

  def donation_params
    strip_unnecessary_params
    clean_donation_money_raised
    params = compact_line_items
    params.require(:donation).permit(:source, :comment, :storage_location_id, :money_raised, :issued_at, :donation_site_id, :product_drive_id, :product_drive_participant_id, :manufacturer_id, line_items_attributes: %i(id item_id quantity)).merge(organization: current_organization)
  end

  def donation_item_params
    params.require(:donation).permit(:barcode_id, :item_id, :quantity)
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:at_storage_location, :by_source, :from_donation_site, :by_product_drive, :by_product_drive_participant, :from_manufacturer)
  end

  # Omits donation_site_id or product_drive_participant_id if those aren't selected as source
  def strip_unnecessary_params
    params[:donation].delete(:donation_site_id) unless params[:donation][:source] == Donation::SOURCES[:donation_site]
    params[:donation].delete(:manufacturer_id) unless params[:donation][:source] == Donation::SOURCES[:manufacturer]
    params[:donation].delete(:product_drive_id) unless params[:donation][:source] == Donation::SOURCES[:product_drive]
    params[:donation].delete(:product_drive_participant_id) unless params[:donation][:source] == Donation::SOURCES[:product_drive]
    params
  end

  # If line_items have submitted with empty rows, clear those out first.
  def compact_line_items
    return params unless params[:donation].key?(:line_items_attributes)

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

  def total_money_raised(donations)
    donations.sum { |d| d.money_raised.to_i }
  end
end
