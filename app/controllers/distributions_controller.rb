# Provides full CRUD+ for Distributions, which are the primary way for inventory to leave a Diaperbank. Most
# Distributions are given out through community partners (either via Partnerbase, or to Partners-on-record). It's
# technically possible to also do Direct Services by having a Partner called "Direct Services" and then issuing
# Distributions to them, though it would lack some of the additional featuers and failsafes that a Diaperbank
# might want if they were doing direct services.
class DistributionsController < ApplicationController
  include DateRangeHelper
  rescue_from Errors::InsufficientAllotment, with: :insufficient_amount!

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
    ActiveRecord::Base.transaction do
      distribution = current_organization.distributions.find(params[:id])
      distribution.storage_location.increase_inventory(distribution)
      distribution.destroy!
    end

    flash[:notice] = "Distribution #{params[:id]} has been reclaimed!"
    redirect_to distributions_path
  end

  def index
    @highlight_id = session.delete(:created_distribution_id)

    @distributions = current_organization
                     .distributions
                     .where(issued_at: selected_range)
                     .includes(:partner, :storage_location, :line_items, :items)
                     .order(created_at: :desc)
                     .class_filter(filter_params)
    @paginated_distributions = @distributions.page(params[:page])
    @total_value_all_distributions = total_value(@distributions)
    @total_value_paginated_distributions = total_value(@paginated_distributions)
    @total_items_all_distributions = total_items(@distributions)
    @total_items_paginated_distributions = total_items(@paginated_distributions)
    @items = current_organization.items.alphabetized
    @partners = @distributions.collect(&:partner).uniq.sort
  end

  def create
    result = DistributionCreateService.new(distribution_params.merge(organization: current_organization), request_id).call

    if result.success?
      flash[:notice] = "Distribution created!"
      session[:created_distribution_id] = result.distribution.id
      redirect_to(distributions_path) && return
    else
      @distribution = result.distribution
      flash[:error] = "Sorry, we weren't able to save the distribution. \n #{@distribution.errors.full_messages.join(', ')} #{result.error}"
      @distribution.line_items.build if @distribution.line_items.count.zero?
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
    if @distribution.future? || current_user.organization_admin?
      @distribution.line_items.build
      @items = current_organization.items.alphabetized
      @storage_locations = current_organization.storage_locations.alphabetized
    else
      flash[:error] = 'To edit a distribution,
      you must be an organization admin or the current date must be major then today.'
      redirect_to distributions_path
    end
  end

  def update
    distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])

    # there are ways to convert issued_at(*i) to Date but they are uglier then just remember it here
    # see examples: https://stackoverflow.com/questions/13605598/how-to-get-a-date-from-date-select-or-select-date-in-rails
    old_issued_at = distribution.issued_at

    if distribution.replace_distribution!(distribution_params)
      @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
      @line_items = @distribution.line_items

      if distribution.issued_at.to_date != old_issued_at.to_date
        send_notification(current_organization.id, @distribution.id, subject: "Your Distribution New Schedule Date is #{distribution.issued_at}")
      end

      schedule_reminder_email(@distribution.id)

      flash[:notice] = "Distribution updated!"
      render :show
    else
      flash[:error] = "Distribution could not be updated! Are you sure there are enough items in inventory to update this distribution?"
      redirect_to action: :edit
    end
  end

  # TODO: This needs a little more context. Is it JSON only? HTML?
  def pick_ups
    @pick_ups = current_organization.distributions
  end

  def picked_up
    if Distribution.find_by(id: params['id'])&.scheduled? && Distribution.find_by(id: params['id'])&.complete!
      flash[:notice] = 'This distribution has been marked as being picked up!'
    else
      flash[:error] = 'Sorry, we encountered an error when trying to mark this distribution as being picked up'
    end

    redirect_to distribution_path
  end

  # TODO: This shouldl probably be private
  def insufficient_amount!
    respond_to do |format|
      format.html { render template: "errors/insufficient", layout: "layouts/application", status: :ok }
      format.json { render nothing: true, status: :ok }
    end
  end

  private

  # If a request id is provided, update the request with the newly created distribution's id
  def update_request(request_atts, distribution_id)
    return if request_atts.blank?

    request = Request.find(request_atts[:id])
    request.update(distribution_id: distribution_id, status: 'fulfilled')
  end

  def send_notification(org, dist, subject: 'Your Distribution')
    PartnerMailerJob.perform_async(org, dist, subject) if Flipper.enabled?(:email_active)
  end

  def schedule_reminder_email(dist)
    DistributionReminderJob.perform_async(dist)
  end

  def distribution_params
    params.require(:distribution).permit(:comment, :agency_rep, :issued_at, :partner_id, :storage_location_id, :reminder_email_enabled, line_items_attributes: %i(item_id quantity _destroy))
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

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:by_item_id, :by_partner)
  end
end
