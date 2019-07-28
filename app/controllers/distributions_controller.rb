# Provides full CRUD+ for Distributions, which are the primary way for inventory to leave a Diaperbank. Most
# Distributions are given out through community partners (either via Partnerbase, or to Partners-on-record). It's
# technically possible to also do Direct Services by having a Partner called "Direct Services" and then issuing
# Distributions to them, though it would lack some of the additional featuers and failsafes that a Diaperbank
# might want if they were doing direct services.
class DistributionsController < ApplicationController
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
                     .includes(:partner, :storage_location, :line_items, :items)
                     .order(created_at: :desc)
                     .class_filter(filter_params)
    @total_value_all_distributions = total_value(@distributions)
    @total_items_all_distributions = total_items(@distributions)
    @items = current_organization.items.alphabetized
    @partners = @distributions.collect(&:partner).uniq.sort
  end

  def create
    @distribution = Distribution.new(distribution_params.merge(organization: current_organization))
    @storage_locations = current_organization.storage_locations

    if @distribution.save
      @distribution.storage_location.decrease_inventory @distribution
      update_request(params[:distribution][:request_attributes], @distribution.id)
      send_notification(current_organization.id, @distribution.id)
      flash[:notice] = "Distribution created!"
      session[:created_distribution_id] = @distribution.id
      redirect_to distributions_path
    else
      flash[:error] = "An error occurred, try again?"
      logger.error "[!] DistributionsController#create failed to save distribution: #{@distribution.errors.full_messages}"
      @distribution.line_items.build if @distribution.line_items.count.zero?
      @items = current_organization.items.alphabetized
      @storage_locations = current_organization.storage_locations.alphabetized
      render :new
    end
  rescue Errors::InsufficientAllotment => ex
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
    flash[:error] = ex.message
    render :new
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
    @distribution.line_items.build
    @items = current_organization.items.alphabetized
    @storage_locations = current_organization.storage_locations.alphabetized
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

  def distribution_params
    params.require(:distribution).permit(:comment, :agency_rep, :issued_at, :partner_id, :storage_location_id, line_items_attributes: %i(item_id quantity _destroy))
  end

  def total_items(distributions)
    distributions.includes(:line_items).sum('line_items.quantity')
  end

  def total_value(distributions)
    distributions.sum(&:value_per_itemizable)
  end

  def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).slice(:by_item_id, :by_partner)
  end
end
