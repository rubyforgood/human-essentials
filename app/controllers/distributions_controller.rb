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

  def reclaim
    ActiveRecord::Base.transaction do
      @distribution_id = params[:id]
      distribution = Distribution.find(params[:id])
      distribution.storage_location.reclaim!(distribution)
      distribution.destroy!
    end

    flash[:notice] = "Distribution #{@distribution_id} has been reclaimed!"
    redirect_to distributions_path
  end

  def index
    @highlight_id = session.delete(:created_distribution_id)

    @distributions = current_organization
                     .distributions
                     .includes(:partner, :storage_location, :line_items, :items)
                     .order(created_at: :desc)
    @total_value_all_distributions = total_value(@distributions)
  end

  def create
    @distribution = Distribution.new(distribution_params.merge(organization: current_organization))

    if @distribution.valid?
      if params[:commit] == "Preview Distribution"
        @distribution.line_items.combine!
        @line_items = @distribution.line_items
        render :show
      else
        @distribution.storage_location.distribute!(@distribution)

        if @distribution.save
          update_request(params[:distribution][:request_attributes], @distribution.id)

          send_notification(current_organization, @distribution)
          flash[:notice] = "Distribution created!"
          session[:created_distribution_id] = @distribution.id
          redirect_to distributions_path
        else
          flash[:error] = "There was an error, try again?"
          render :new
        end
      end
    else
      @storage_locations = current_organization.storage_locations
      flash[:error] = "An error occurred, try again?"
      logger.error "failed to save distribution: #{@distribution.errors.full_messages}"
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
    @items = current_organization.items.alphabetized
    @storage_locations = current_organization.storage_locations
  end

  def show
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    @line_items = @distribution.line_items
  end

  def edit
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    @distribution.line_items.build
    @items = current_organization.items.alphabetized
    @storage_locations = current_organization.storage_locations
  end

  def update
    distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    if distribution.storage_location.update_distribution!(distribution, distribution_params)
      @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
      @line_items = @distribution.line_items
      flash[:notice] = "Distribution updated!"
      render :show
    else
      flash[:error] = "Distribution could not be updated! Are you sure there are enough items in inventory to update this distribution?"
      redirect_to action: :edit
    end
  end

  def pick_ups
    @pick_ups = current_organization.distributions
  end

  def insufficient_amount!
    respond_to do |format|
      format.html { render template: "errors/insufficient", layout: "layouts/application", status: :ok }
      format.json { render nothing: true, status: :ok }
    end
  end

  private

  # If a request id is provided, update the request with the newly created distribution's id
  def update_request(request_atts, distribution_id)
    if request_atts
      Request.find(request_atts[:id]).update(distribution_id: distribution_id)
    end
  end

  def send_notification(org, dist)
    PartnerMailerJob.perform_async(org, dist) if Flipper.enabled?(:email_active)
  end

  def distribution_params
    params.require(:distribution).permit(:comment, :agency_rep, :issued_at, :partner_id, :storage_location_id, line_items_attributes: %i(item_id quantity _destroy))
  end

  def total_value(distributions)
    total_value_all_distributions = 0
    distributions.each do |distribution|
      total_value_all_distributions += distribution.value_per_itemizable
    end
    total_value_all_distributions
  end
end
