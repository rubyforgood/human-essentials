class FamiliesController < ApplicationController
  before_action :authenticate_partner!

  helper_method :family, :families
  attr_reader :families

  def index
    @families = current_partner.families
  end

  def show; end

  def new
    @family = current_partner.families.new
  end

  def edit; end

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

  def destroy
    family.destroy
    respond_to do |format|
      format.html { redirect_to families_url, notice: "Family was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def family
    @family ||= current_partner.families.find(params[:id])
  end

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
