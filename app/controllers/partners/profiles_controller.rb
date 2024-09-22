module Partners
  class ProfilesController < BaseController
    def show; end

    def edit
      @counties = County.in_category_name_order
      @client_share_total = current_partner.profile.client_share_total

      if Flipper.enabled?("partner_step_form")
        @open_section = params[:open_section] || "agency_information"
        # temp debug
        Rails.logger.info("=== [ProfilesController#edit] open_section=#{@open_section}")
        render "partners/profiles/step/edit"
      else
        render "edit"
      end
    end

    def update
      @counties = County.in_category_name_order
      result = PartnerProfileUpdateService.new(current_partner, partner_params, profile_params).call
      if result.success?
        if Flipper.enabled?("partner_step_form")
          submitted_partial = params[:submitted_partial]
          open_section = next_step(submitted_partial)
          redirect_to edit_partners_profile_path(open_section: open_section)
        else
          flash[:success] = "Details were successfully updated."
          redirect_to partners_profile_path
        end
      else
        flash[:error] = "There is a problem. Try again:  %s" % result.error
        render Flipper.enabled?("partner_step_form") ? "partners/profiles/step/edit" : :edit
      end
    end

    private

    # TODO: 4504 move this to somewhere easier to test like a service
    # TODO: 4504 implement logic to determine which section should be next -> complexity dynamics!
    # Make use of partner.partials_to_show for dynamic sections
    # | Partial                         | Converted to Step | Type    | Default   | Next                            |
    # | ------------------------------- | ----------------- | ------- | --------- | ------------------------------- |
    # | agency_information              | true              | static  | expanded  | program_delivery_address   |
    # | program_delivery_address        | true              | static  | collapsed | media_information               |
    # | media_information               | true              | dynamic | collapsed | agency_stability                |
    # | agency_stability                | true              | dynamic | collapsed | organizational_capacity         |
    # | organizational_capacity         | true              | dynamic | collapsed | sources_of_funding              |
    # | sources_of_funding              | true              | dynamic | collapsed | area_served                     |
    # | area_served                     | true              | dynamic | collapsed | population_served               |
    # | population_served               | true              | dynamic | collapsed | executive_director              |
    # | executive_director              | true              | dynamic | collapsed | pick_up_person                  |
    # | pick_up_person                  | true              | dynamic | collapsed | agency_distribution_information |
    # | agency_distribution_information | true              | dynamic | collapsed | attached_documents              |
    # | attached_documents              | true              | dynamic | collapsed | partner_settings                |
    # | partner_settings                | true              | static  | collapsed | NA                              |
    def next_step(submitted_partial)
      case submitted_partial
      when "agency_information"
        "program_delivery_address"
      when "program_delivery_address"
        current_partner.partials_to_show.first
      when current_partner.partials_to_show.include?(submitted_partial)
        next_partner_partial(submitted_partial)
      when "partner_settings"
        "NA"
      else
        "agency_information"
      end
    end

    # TODO: 4504 move this to somewhere easier to test like a service
    def next_partner_partial(submitted_partial)
      index = current_partner.partials_to_show.index(submitted_partial)
      if index
        current_partner.partials_to_show[index + 1]
      else
        "agency_information"
      end
    end

    def partner_params
      params.require(:partner).permit(:name)
    end

    def profile_params
      params.require(:partner).require(:profile).permit(
        :agency_type,
        :other_agency_type,
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
        :instagram,
        :no_social_media_presence,
        :founded,
        :form_990,
        :proof_of_form_990,
        :program_name,
        :program_description,
        :program_age,
        :case_management,
        :evidence_based,
        :essentials_use,
        :receives_essentials_from_other,
        :currently_provide_diapers,
        :program_address1,
        :program_address2,
        :program_city,
        :program_state,
        :program_zip_code,
        :client_capacity,
        :storage_space,
        :describe_storage_space,
        :income_requirement_desc,
        :income_verification,
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
        :executive_director_name,
        :executive_director_phone,
        :executive_director_email,
        :primary_contact_name,
        :primary_contact_phone,
        :primary_contact_mobile,
        :primary_contact_email,
        :pick_up_name,
        :pick_up_phone,
        :pick_up_email,
        :distribution_times,
        :new_client_times,
        :more_docs_required,
        :sources_of_funding,
        :sources_of_diapers,
        :essentials_budget,
        :essentials_funding_source,
        :enable_child_based_requests,
        :enable_individual_requests,
        :enable_quantity_based_requests,
        served_areas_attributes: %i[county_id client_share _destroy],
        documents: []
      ).select { |k, v| k.present? }
    end
  end
end
