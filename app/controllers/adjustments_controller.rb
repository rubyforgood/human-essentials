class AdjustmentsController < ApplicationController
  before_action :set_adjustment, only: [:show, :edit, :update, :destroy]

  # GET /adjustments
  # GET /adjustments.json
  def index
    @adjustments = current_organization.adjustments.all
  end

  # GET /adjustments/1
  # GET /adjustments/1.json
  def show
  end

  # GET /adjustments/new
  def new
    @adjustment = current_organization.adjustments.new
  end

  # GET /adjustments/1/edit
  def edit
  end

  # POST /adjustments
  def create
    @adjustment = current_organization.adjustments.new(adjustment_params)

    respond_to do |format|
      if @adjustment.save
        format.html { redirect_to @adjustment, notice: 'Adjustment was successfully created.' }
        format.json { render :show, status: :created, location: @adjustment }
      else
        format.html { render :new }
        format.json { render json: @adjustment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /adjustments/1
  def update
    respond_to do |format|
      if @adjustment.update(adjustment_params)
        format.html { redirect_to @adjustment, notice: 'Adjustment was successfully updated.' }
        format.json { render :show, status: :ok, location: @adjustment }
      else
        format.html { render :edit }
        format.json { render json: @adjustment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /adjustments/1
  def destroy
    @adjustment.destroy
    respond_to do |format|
      format.html { redirect_to adjustments_url, notice: 'Adjustment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_adjustment
    @adjustment = current_organization.adjustments.find(params[:id])
  end

  def adjustment_params
    params.require(:adjustment).permit(:organization_id, :storage_location_id, :comment)
  end
end
