require "csv"
module Partners
  class FamiliesController < BaseController
    layout 'partners/application'

    helper_method :sort_column, :sort_direction

    def index
      @filterrific = initialize_filterrific(
        current_partner.families
                       .order(sort_order),
        params[:filterrific]
      ) || return

      @families = @filterrific.find

      respond_to do |format|
        format.js
        format.html
        format.csv do
          send_data Partners::Family.generate_csv(@families), filename: "Families-#{Time.zone.today}.csv"
        end
      end
    end

    def show
      @family = current_partner.families.find(params[:id])
    end

    def new
      @family = current_partner.families.new
    end

    def edit
      @family = current_partner.families.find(params[:id])
    end

    def create
      @family = current_partner.families.new(family_params)

      if @family.save
        redirect_to @family, notice: "Family was successfully created."
      else
        render :new
      end
    end

    def update
      @family = current_partner.families.find(params[:id])

      if @family.update(family_params)
        redirect_to partners_family_path(@family), notice: "Family was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      family = current_partner.families.find_by(id: params[:id])

      if family.present?
        family.destroy
        redirect_to families_url, notice: "Family was successfully destroyed."
      end
    end

    private

    def family_params
      params.require(:partners_family).permit(
        :case_manager,
        :comments,
        :guardian_county,
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

    def sort_order
      sort_column + ' ' + sort_direction
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    def sort_column
      Family.column_names.include?(params[:sort]) ? params[:sort] : "guardian_last_name"
    end
  end
end
