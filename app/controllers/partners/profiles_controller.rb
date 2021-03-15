module Partners
  class ProfilesController < BaseController
    layout 'partners/application'
    # before_action :set_partner, only: [:show, :edit, :update, :destroy]

    def index
      # @partners = Partner.all
      # authorize @partners
    end

    def show
      @partner = current_partner
    end

    def edit; end

    def approve
      @partner = Partner.find(params[:partner_id])
      @partner.approve_me
      flash[:success] = "You have submitted your details for approval."
      redirect_to @partner
    end

    def update
      if @partner.update(partner_params)
        flash[:success] = "Details were successfully updated."
        redirect_to @partner
      else
        render :edit
      end
    end

    def destroy
      @partner.destroy
      flash[:success] = "Partner was successfully destroyed."
      redirect_to partners_path
    end

    private

    # def set_partner
    # @partner = authorize Partner.find(params[:id])
    # end

    def partner_params
      params.require(:partner).permit(
        :name,
        :agency_type,
        :other_agency_type,
        :partner_status,
        :proof_of_partner_status,
        :agency_mission,
        :address1,
        :address2,
        :city,
        :state,
        :zip_code,
        :website,
        :facebook,
        :twitter,
        :founded,
        :form_990,
        :proof_of_form_990,
        :program_name,
        :program_description,
        :program_age,
        :case_management,
        :evidence_based,
        :evidence_based_description,
        :program_client_improvement,
        :diaper_use,
        :other_diaper_use,
        :currently_provide_diapers,
        :turn_away_child_care,
        :program_address1,
        :program_address2,
        :program_city,
        :program_state,
        :program_zip_code,
        :max_serve,
        :incorporate_plan,
        :responsible_staff_position,
        :storage_space,
        :describe_storage_space,
        :trusted_pickup,
        :income_requirement_desc,
        :serve_income_circumstances,
        :income_verification,
        :internal_db,
        :maac,
        :population_black,
        :population_white,
        :population_hispanic,
        :population_asian,
        :population_american_indian,
        :population_island,
        :population_multi_racial,
        :population_other,
        :zips_served,
        :at_fpl_or_below,
        :above_1_2_times_fpl,
        :greater_2_times_fpl,
        :poverty_unknown,
        :ages_served,
        :executive_director_name,
        :executive_director_phone,
        :executive_director_email,
        :program_contact_name,
        :program_contact_phone,
        :program_contact_mobile,
        :program_contact_email,
        :pick_up_method,
        :pick_up_name,
        :pick_up_phone,
        :pick_up_email,
        :distribution_times,
        :new_client_times,
        :more_docs_required,
        :sources_of_funding,
        :sources_of_diapers,
        :diaper_budget,
        :diaper_funding_source,
        documents: []
      )
    end
  end
end
