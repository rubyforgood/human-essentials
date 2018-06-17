class DistributionsController < ApplicationController
  rescue_from Errors::InsufficientAllotment, with: :insufficient_amount!

  def print
    @distribution = Distribution.find(params[:id])
    @filename = format("%s %s.pdf", @distribution.partner.name, sortable_date(@distribution.created_at))
  end

  def reclaim
    @distribution = Distribution.find(params[:id])
    @distribution.storage_location.reclaim!(@distribution)

    flash[:notice] = "Distribution #{@distribution.id} has been reclaimed!"
    redirect_to distributions_path
  end

  def index
    @distributions = current_organization
                     .distributions
                     .includes(:partner, :storage_location, :line_items, :items)
                     .order(created_at: :desc)
  end

  def create
    @distribution = Distribution.new(distribution_params.merge(organization: current_organization))

    if @distribution.valid?
      if params[:commit] == "Preview Distribution"
        @distribution.combine_duplicates
        @line_items = @distribution.line_items
        render :show
      else
        @distribution.storage_location.distribute!(@distribution)

        if @distribution.save
          flash[:notice] = "Distribution created!"
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
    @distribution.line_items.build
    @distribution.copy_from_donation(params[:donation_id], params[:storage_location_id])
    @items = current_organization.items.alphabetized
    @storage_locations = current_organization.storage_locations
  end

  def show
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    @line_items = @distribution.line_items
  end

  def insufficient_amount!
    respond_to do |format|
      format.html { render template: "errors/insufficient", layout: "layouts/application", status: :ok }
      format.json { render nothing: true, status: :ok }
    end
  end

  private

  def distribution_params
    params.require(:distribution).permit(:comment, :agency_rep, :issued_at, :partner_id, :storage_location_id, line_items_attributes: %i(item_id quantity _destroy))
  end
end
