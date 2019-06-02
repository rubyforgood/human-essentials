class FamiliesController < ApplicationController
  before_action :authenticate_partner!

  helper_method :family, :families
  attr_reader :families

  # GET /families
  # GET /families.json
  def index
    @families = current_partner.families
  end

  # GET /families/1
  # GET /families/1.json
  def show; end

  # GET /families/new
  def new
    @family = current_partner.families.new
  end

  # GET /families/1/edit
  def edit; end

  # POST /families
  # POST /families.json
  def create
    @family = current_partner.families.new(family_params)

    respond_to do |format|
      if @family.save
        format.html { redirect_to @family, notice: "Family was successfully created." }
        format.json { render :show, status: :created, location: @family }
      else
        format.html { render :new }
        format.json { render json: @family.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /families/1
  # PATCH/PUT /families/1.json
  def update
    respond_to do |format|
      if family.update(family_params)
        format.html { redirect_to family, notice: "Family was successfully updated." }
        format.json { render :show, status: :ok, location: family }
      else
        format.html { render :edit }
        format.json { render json: family.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /families/1
  # DELETE /families/1.json
  def destroy
    family.destroy
    respond_to do |format|
      format.html { redirect_to families_url, notice: "Family was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def family
    @family ||= current_partner.families.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def family_params
    params.require(:family).permit(
      :agency_guardian_id,
      :comments,
      :guardian_country,
      :guardian_employed,
      :guardian_employment_type,
      :guardian_first_name,
      :guardian_health_insurance,
      :guardian_last_name,
      :guardian_monthly_pay,
      :guardian_phone,
      :guardian_zip_code,
      :home_adult_count,
      :home_child_count,
      :home_young_child_count,
      :sources_of_income
    )
  end
end
