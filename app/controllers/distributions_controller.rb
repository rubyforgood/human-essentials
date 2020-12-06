# Provides full CRUD+ for Distributions, which are the primary way for inventory to leave a Diaperbank. Most
# Distributions are given out through community partners (either via Partnerbase, or to Partners-on-record). It's
# technically possible to also do Direct Services by having a Partner called "Direct Services" and then issuing
# Distributions to them, though it would lack some of the additional featuers and failsafes that a Diaperbank
# might want if they were doing direct services.
class DistributionsController < ApplicationController
  include DateRangeHelper
  include DistributionHelper

  def print
    @distribution = Distribution.find(params[:id])
    respond_to do |format|
      format.any do
        pdf = DistributionPdf.new(current_organization, @distribution)
        send_data pdf.render,
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
                     .apply_filters(filter_params, helpers.selected_range)
    @paginated_distributions = @distributions.page(params[:page])
    @total_value_all_distributions = total_value(@distributions)
    @total_value_paginated_distributions = total_value(@paginated_distributions)
    @total_items_all_distributions = total_items(@distributions)
    @total_items_paginated_distributions = total_items(@paginated_distributions)
    @items = current_organization.items.alphabetized
    @storage_locations = current_organization.storage_locations.alphabetized
    @partners = @distributions.collect(&:partner).uniq.sort_by(&:name)
    @selected_item = filter_params[:by_item_id]
    @selected_partner = filter_params[:by_partner]
    @selected_status = filter_params[:by_state]
    @selected_location = filter_params[:by_location]
    # FIXME: one of these needs to be removed but it's unclear which at this point
    @statuses = Distribution.states.transform_keys(&:humanize)

    respond_to do |format|
      format.html
      format.csv { send_data Distribution.generate_csv(@distributions, @items.collect(&:name).sort), filename: "Distributions-#{Time.zone.today}.csv" }
    end
  end

  def create
    result = DistributionCreateService.new(distribution_params.merge(organization: current_organization), request_id).call

    if result.success?
      session[:created_distribution_id] = result.distribution.id
      @distribution = result.distribution
      flash[:notice] = "Distribution created!"

      perform_inventory_check
      redirect_to(distribution_path(result.distribution)) && return
    else
      @distribution = result.distribution
      flash[:error] = insufficient_error_message(result.error.message)
      @distribution.line_items.build if @distribution.line_items.size.zero?
      @items = current_organization.items.alphabetized
      @storage_locations = current_organization.storage_locations.alphabetized
      render :new
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
    @storage_locations = current_organization.storage_locations.alphabetized
  end

  def show
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    @line_items = @distribution.line_items
  end

  def edit
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    if (!@distribution.complete? && @distribution.future?) || current_user.organization_admin?
      @distribution.line_items.build if @distribution.line_items.size.zero?
      @items = current_organization.items.alphabetized
      @storage_locations = current_organization.storage_locations.alphabetized
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
      schedule_reminder_email(@distribution)

      perform_inventory_check
      redirect_to @distribution, notice: "Distribution updated!"
    else
      flash[:error] = insufficient_error_message(result.error.message)
      @distribution.line_items.build if @distribution.line_items.size.zero?
      @items = current_organization.items.alphabetized
      @storage_locations = current_organization.storage_locations.alphabetized
      render :edit
    end
  end

  # TODO: This needs a little more context. Is it JSON only? HTML?
  def schedule
    @pick_ups = current_organization.distributions
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
    "Sorry, we weren't able to save the distribution. \n #{@distribution.errors.full_messages.join(', ')} #{details}"
  end

  def send_notification(org, dist, subject: 'Your Distribution', distribution_changes: {})
    PartnerMailerJob.perform_now(org, dist, subject, distribution_changes) if Flipper.enabled?(:email_active)
  end

  def schedule_reminder_email(distribution)
    return if distribution.past? || !distribution.partner.send_reminders

    DistributionMailer.delay_until(distribution.issued_at - 1.day).reminder_email(distribution.id)
  end

  def distribution_params
    params.require(:distribution).permit(:comment, :agency_rep, :issued_at, :partner_id, :storage_location_id, :reminder_email_enabled, :delivery_method, line_items_attributes: %i(item_id quantity _destroy))
  end

  def request_id
    params.dig(:distribution, :request_attributes, :id)
  end

  def total_items(distributions)
    LineItem.where(itemizable_type: "Distribution", itemizable_id: distributions.pluck(:id)).sum('quantity')
  end

  def total_value(distributions)
    distributions.sum(&:value_per_itemizable)
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

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_item_id, :by_partner, :by_state, :by_location)
  end

  def perform_inventory_check
    inventory_check_result = InventoryCheckService.new(@distribution).call

    if inventory_check_result.error.present?
      flash[:error] = inventory_check_result.error
    end
    if inventory_check_result.alert.present?
      flash[:alert] = inventory_check_result.alert
    end
  end
end
