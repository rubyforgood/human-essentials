class DistributionsController < ApplicationController

  rescue_from Errors::InsufficientAllotment, with: :insufficient_amount!

  def print
    @distribution = Distribution.find(params[:id])
    @filename = "%s %s.pdf" % [@distribution.partner.name, sortable_date(@distribution.created_at)]
  end

  def reclaim
    @distribution = Distribution.find(params[:id])
    @distribution.storage_location.reclaim!(@distribution)
    @distribution.destroy

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
      logger.error "failed to save distribution: #{ @distribution.errors.full_messages }"
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

  def edit
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    @distribution.line_items.build
    @items = current_organization.items.alphabetized
    @storage_locations = current_organization.storage_locations
  end

  def update
    # FIXME: Fix this

    # find distribution from db
    # determine if storage location changed
    # check if new distribution will be valid
    # if not valid, go back to edit page with errors
    # if valid AND storage location is changed, restore old distribution
    # make the distribution changes
      # subtract from inventory
      # saving distribution object
    # redirect to index page



    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    old_storage_location_id = @distribution.storage_location_id
    if old_storage_location_id != distribution_params[:storage_location_id]

    end

    @distribution.assign_attributes(distribution_params)

    if @distribution.valid?
      @distribution.storage_location.adjust_distribution!(@distribution)

      if @distribution.save
        flash[:notice] = "Distribution updated!"
        redirect_to distributions_path
      else
        flash[:error] = "There was an error, try again?"
        render :edit
      end
    else
      @storage_locations = current_organization.storage_locations
      flash[:error] = "An error occurred, try again?"
      logger.error "failed to save distribution: #{ @distribution.errors.full_messages }"
      render :edit
    end
  rescue Errors::InsufficientAllotment => ex
    @storage_locations = current_organization.storage_locations
    @items = current_organization.items.alphabetized
    flash[:error] = ex.message
    render :edit
  end

  def show
    @distribution = Distribution.includes(:line_items).includes(:storage_location).find(params[:id])
    @line_items = @distribution.line_items
  end

  def insufficient_amount!
    respond_to do |format|
      format.html { render template: "errors/insufficient", layout: "layouts/application", status: 200 }
      format.json { render nothing: true, status: 200 }
    end
  end

  private

  def distribution_params
    params.require(:distribution).permit(:comment, :agency_rep, :issued_at, :partner_id, :storage_location_id, line_items_attributes: [:id, :item_id, :quantity, :_destroy])
  end
end
