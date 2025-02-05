# Provides full CRUD+ for Distributions, which are the primary way for inventory to leave a Diaperbank. Most
# Distributions are given out through community partners (either via Partnerbase, or to Partners-on-record). It's
# technically possible to also do Direct Services by having a Partner called "Direct Services" and then issuing
# Distributions to them, though it would lack some of the additional featuers and failsafes that a Diaperbank
# might want if they were doing direct services.
class DistributionsController < ApplicationController
  include DateRangeHelper
  include DistributionHelper

  before_action :enable_turbo!, only: %i[new show]
  skip_before_action :authenticate_user!, only: %i(calendar)
  skip_before_action :authorize_user, only: %i(calendar)

  def print
    @distribution = Distribution.find(params[:id])
    respond_to do |format|
      format.any do
        pdf = DistributionPdf.new(current_organization, @distribution)
        send_data pdf.compute_and_render,
                  filename: format("%s %s.pdf", @distribution.partner.name, sortable_date(@distribution.created_at)),
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def destroy
    result = DistributionDestroyService.new(params[:id]).call

    if result.success?
      flash[:notice] = "Distribution #{params[:id]} has been reclaimed!"
    else
      flash[:error] = "Could not destroy distribution #{params[:id]}. Please contact technical support."
    end

    redirect_to distributions_path
  end

  def index
    setup_date_range_picker

    @highlight_id = session.delete(:created_distribution_id)

    @distributions = current_organization
                     .distributions
                     .order(issued_at: :desc)
                     .includes(:partner, :storage_location)
                     .class_filter(scope_filters)
    @paginated_distributions = @distributions.page(params[:page])
    @items = current_organization.items.alphabetized.select(:id, :name)
    @item_categories = current_organization.item_categories.select(:id, :name)
    @storage_locations = current_organization.storage_locations.active.alphabetized.select(:id, :name)
    @partners = current_organization.partners.active.alphabetized.select(:id, :name)
    @selected_item = filter_params[:by_item_id].presence
    @distribution_totals = DistributionTotalsService.new(current_organization.distributions, scope_filters)
    @total_value_all_distributions = @distribution_totals.total_value
    @total_items_all_distributions = @distribution_totals.total_quantity
    paginated_ids = @paginated_distributions.ids
    @total_value_paginated_distributions = @distribution_totals.total_value(paginated_ids)
    @total_items_paginated_distributions = @distribution_totals.total_quantity(paginated_ids)
    @selected_item_category = filter_params[:by_item_category_id]
    @selected_partner = filter_params[:by_partner]
    @selected_status = filter_params[:by_state]
    @selected_location = filter_params[:by_location]
    # FIXME: one of these needs to be removed but it's unclear which at this point
    @statuses = Distribution.states.transform_keys(&:humanize)
    @distributions_with_inactive_items = @distributions.joins(:inactive_items).pluck(:id)

    respond_to do |format|
      format.html
      format.csv do
        send_data Exports::ExportDistributionsCSVService.new(distributions: @distributions.includes(line_items: :item), organization: current_organization, filters: scope_filters).generate_csv, filename: "Distributions-#{Time.zone.today}.csv"
      end
    end
  end

  # This endpoint is in support of displaying a confirmation modal before a distribution is created.
  # Since the modal should only be shown for a valid distribution, client side JS will invoke this
  # endpoint, and if the distribution is valid, this endpoint also returns the HTML for the modal content.
  # Important: The distribution model is intentionally NOT saved to the database at this point because
  # the user has not yet confirmed that they want to create it.
  def validate
    @dist = Distribution.new(distribution_params.merge(organization: current_organization))
    @dist.line_items.combine!
    if @dist.valid?
      body = render_to_string(template: 'distributions/validate', formats: [:html], layout: false)
      render json: {valid: true, body: body}
    else
      render json: {valid: false}
    end
  end

  def create
    dist = Distribution.new(distribution_params.merge(organization: current_organization))
    result = DistributionCreateService.new(dist, request_id).call

    if result.success?
      session[:created_distribution_id] = result.distribution.id
      @distribution = result.distribution

      perform_inventory_check
      schedule_reminder_email(result.distribution) if @distribution.reminder_email_enabled

      respond_to do |format|
        format.turbo_stream do
          redirect_to distribution_path(result.distribution), notice: "Distribution created!"
        end
      end
    else
      @distribution = result.distribution
      if request_id
        # Using .find here instead of .find_by so we can raise a error if request_id
        # does not match any known Request
        @distribution.request = Request.find(request_id)
      end
      if @distribution.line_items.size.zero?
        @distribution.line_items.build
      elsif request_id
        @distribution.initialize_request_items
      end
      @items = current_organization.items.active.alphabetized
      @partner_list = current_organization.partners.where.not(status: 'deactivated').alphabetized

      inventory = View::Inventory.new(@distribution.organization_id)
      @storage_locations = current_organization.storage_locations.active.alphabetized.select do |storage_loc|
        inventory.quantity_for(storage_location: storage_loc.id).positive?
      end
      if @distribution.storage_location.present?
        @item_labels_with_quantities = inventory
          .items_for_location(@distribution.storage_location.id, include_omitted: true)
          .map(&:to_dropdown_option)
      end

      flash_error = insufficient_error_message(result.error.message)

      respond_to do |format|
        format.turbo_stream do
          flash.now[:error] = flash_error
          render turbo_stream: [
            turbo_stream.replace(@distribution, partial: "form", locals: {distribution: @distribution, date_place_holder: @distribution.issued_at}),
            turbo_stream.replace("flash", partial: "shared/flash")
          ], status: :bad_request
        end
      end
    end
  end

  def new
    @distribution = Distribution.new
    if params[:request_id]
      @distribution.copy_from_request(params[:request_id])
    else
      @distribution.line_items.build
      @distribution.copy_from_donation(params[:donation_id], params[:storage_location_id])
    end
    @items = current_organization.items.active.alphabetized
    @partner_list = current_organization.partners.where.not(status: 'deactivated').alphabetized

    inventory = View::Inventory.new(current_organization.id)
    @storage_locations = current_organization.storage_locations.active.alphabetized.select do |storage_loc|
      inventory.quantity_for(storage_location: storage_loc.id).positive?
    end
  end

  def show
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    @line_items = @distribution.line_items

    @total_quantity = @distribution.total_quantity
    @total_package_count = @line_items.sum { |item| item.has_packages || 0 }
    if @total_package_count.zero?
      @total_package_count = nil
    end
  end

  def edit
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    @distribution.initialize_request_items
    if (!@distribution.complete? && @distribution.future?) ||
        current_user.has_cached_role?(Role::ORG_ADMIN, current_organization)
      @distribution.line_items.build if @distribution.line_items.size.zero?
      @items = current_organization.items.active.alphabetized
      @partner_list = current_organization.partners.alphabetized
      @audit_warning = current_organization.audits
        .where(storage_location_id: @distribution.storage_location_id)
        .where("updated_at > ?", @distribution.created_at).any?
      inventory = View::Inventory.new(@distribution.organization_id)
      @storage_locations = current_organization.storage_locations.active.alphabetized.select do |storage_loc|
        !inventory.quantity_for(storage_location: storage_loc.id).negative?
      end
    else
      redirect_to distributions_path, error: 'To edit a distribution,
      you must be an organization admin or the current date must be later than today.'
    end
  end

  def update
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    result = DistributionUpdateService.new(@distribution, distribution_params).call

    if result.success?
      if result.resend_notification? && @distribution.partner&.send_reminders
        send_notification(current_organization.id, @distribution.id, subject: "Your Distribution Has Changed", distribution_changes: result.distribution_content.changes)
      end
      schedule_reminder_email(@distribution) if @distribution.reminder_email_enabled

      perform_inventory_check
      redirect_to @distribution, notice: "Distribution updated!"
    else
      flash.now[:error] = insufficient_error_message(result.error.message)
      @distribution.line_items.build if @distribution.line_items.size.zero?
      @distribution.initialize_request_items
      @items = current_organization.items.active.alphabetized
      @partner_list = current_organization.partners.alphabetized
      @storage_locations = current_organization.storage_locations.active.alphabetized
      render :edit
    end
  end

  def itemized_breakdown
    setup_date_range_picker

    distributions = current_organization.distributions.during(helpers.selected_range)
    itemized_distribution_data_csv = DistributionItemizedBreakdownService
      .new(organization: current_organization, distribution_ids: distributions.pluck(:id))
      .fetch_csv

    respond_to do |format|
      format.csv do
        send_data itemized_distribution_data_csv, filename: "Itemized-Breakdown-Distributions-#{Time.zone.today}.csv"
      end
    end
  end

  # TODO: This needs a little more context. Is it JSON only? HTML?
  def schedule
    respond_to do |format|
      format.html
      format.json do
        start_at = params[:start].to_datetime
        end_at = params[:end].to_datetime
        @pick_ups = current_organization.distributions.includes(:partner).where(issued_at: start_at..end_at)
      end
    end
  end

  def calendar
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secret_key_base[0..31])
    organization_id = crypt.decrypt_and_verify(CGI.unescape(params[:hash]))

    render body: CalendarService.calendar(organization_id), content_type: Mime::Type.lookup("text/calendar")
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
    head :unauthorized
  end

  def picked_up
    distribution = current_organization.distributions.find(params[:id])

    if !distribution.complete? && distribution.complete!
      flash[:notice] = 'This distribution has been marked as being completed!'
    else
      flash[:error] = 'Sorry, we encountered an error when trying to mark this distribution as being completed'
    end

    redirect_back(fallback_location: distribution_path)
  end

  def pickup_day
    @pick_ups = current_organization.distributions.during(pickup_date).order(issued_at: :asc)
    @daily_items = daily_items(@pick_ups)
    @selected_date = pickup_day_params[:during]&.to_date || Time.zone.now.to_date
  end

  private

  def insufficient_error_message(details)
    "Sorry, we weren't able to save the distribution. \n #{details}"
  end

  def send_notification(org, dist, subject: 'Your Distribution', distribution_changes: {})
    PartnerMailerJob.perform_now(org, dist, subject, distribution_changes)
  end

  def schedule_reminder_email(distribution)
    return if distribution.past? || !distribution.partner.send_reminders

    DistributionMailer.reminder_email(distribution.id).deliver_later(wait_until: distribution.issued_at - 1.day)
  end

  def distribution_params
    params.require(:distribution).permit(:comment, :agency_rep, :issued_at, :partner_id, :storage_location_id, :reminder_email_enabled, :delivery_method, :shipping_cost, line_items_attributes: %i(item_id quantity _destroy))
  end

  def request_id
    params.dig(:distribution, :request_attributes, :id)
  end

  def daily_items(pick_ups)
    item_groups = LineItem.where(itemizable_type: "Distribution", itemizable_id: pick_ups.pluck(:id)).group_by(&:item_id)
    item_groups.map do |_id, items|
      {
        name: items.first.item.name,
        quantity: items.sum(&:quantity),
        package_count: items.sum { |item| item.package_count.to_i }
      }
    end
  end

  def scope_filters
    filter_params
      .except(:date_range)
      .merge(during: helpers.selected_range)
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params
      .require(:filters)
      .permit(:by_item_id, :by_item_category_id, :by_partner, :by_state, :by_location, :date_range)
  end

  def perform_inventory_check
    inventory_check_result = InventoryCheckService.new(@distribution).call

    alerts = [inventory_check_result.minimum_alert, inventory_check_result.recommended_alert]
    merged_alert = alerts.compact.join("\n")
    flash[:alert] = merged_alert if merged_alert.present?
  end
end
