class FamiliesController < ApplicationController
  before_action :authenticate_user!

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

    if @family.save
      redirect_to @family, notice: "Family was successfully created."
    else
      render :new
    end
  end

  def update
    if family.update(family_params)
      redirect_to family, notice: "Family was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    family.destroy
    redirect_to families_url, notice: "Family was successfully destroyed."
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
      :military,
      sources_of_income: []
    )
  end
end
