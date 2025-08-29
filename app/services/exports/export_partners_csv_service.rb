module Exports
  class ExportPartnersCSVService
    # Currently, the @partners are already loaded by the controllers that are delegating exporting
    # to this service object; this is happening within the same request/response cycle, so it's already
    # in memory, so we can pass that collection in directly. Should this be moved to a background / async
    # job, we will need to pass in a collection of IDs instead.
    def initialize(partners, organization)
      @partners = partners.includes(:profile)
      # Assumes that all of the partners belong to the same organization. This is true for the time being
      # and, were that to change, base_table would need to be reworked anyway to account for partners from
      # different orgs having different partials enabled, and thus different columns in the CSV.
      @partials_to_show = organization.partials_to_show
    end

    def generate_csv
      CSV.generate(headers: true) do |csv|
        csv << headers
        partners.each { |partner| csv << build_row_data(partner) }
      end
    end

    private

    attr_reader :partners

    def base_table
      table = {
        "Agency Name" => ->(partner) { partner.name },
        "Agency Email" => ->(partner) { partner.email },
        "Notes" => ->(partner) { partner.notes },
        "Agency Type" => ->(partner) { I18n.t(partner.profile.agency_type, scope: :partners_profile) }, # Columns from the agency_information partial
        "Other Agency Type" => ->(partner) { partner.profile.other_agency_type },
        "Agency Mission" => ->(partner) { partner.profile.agency_mission },
        "Agency Address" => ->(partner) {
          (partner.profile.address1.blank? || partner.profile.address2.blank?) ?
          "" : "#{partner.profile.address1}, #{partner.profile.address2}"
        },
        "Agency City" => ->(partner) { partner.profile.city },
        "Agency State" => ->(partner) { partner.profile.state },
        "Agency Zip Code" => ->(partner) { partner.profile.zip_code },
        "Program/Delivery Address" => ->(partner) {
          (partner.profile.program_address1.blank? || partner.profile.program_address2.blank?) ?
          "" : "#{partner.profile.program_address1}, #{partner.profile.program_address2}"
        },
        "Program City" => ->(partner) { partner.profile.program_city },
        "Program State" => ->(partner) { partner.profile.program_state },
        "Program Zip Code" => ->(partner) { partner.profile.program_zip_code }
      }

      media_information_col(table)
      agency_stability_col(table)
      organizational_capacity_col(table)
      sources_of_funding_col(table)
      area_served_col(table)
      population_served_col(table)
      executive_director_col(table)
      pick_up_person_col(table)
      agency_distribution_information_col(table)

      table["Quantity-based Requests"] = ->(partner) { partner.profile.enable_quantity_based_requests } # Columns from the partner_settings partial
      table["Child-based Requests"] = ->(partner) { partner.profile.enable_child_based_requests }
      table["Individual Requests"] = ->(partner) { partner.profile.enable_individual_requests }

      table["Providing Diapers"] = ->(partner) { diaper_statuses[partner.id] }
      table["Providing Period Supplies"] = ->(partner) { period_supplies_statuses[partner.id] }

      table
    end

    def media_information_col(table)
      if @partials_to_show.include? "media_information"
        table["Agency Website"] = ->(partner) { partner.profile.website }
        table["Facebook"] = ->(partner) { partner.profile.facebook }
        table["Twitter"] = ->(partner) { partner.profile.twitter }
        table["Instagram"] = ->(partner) { partner.profile.instagram }
        table["No Social Media Presence"] = ->(partner) { partner.profile.no_social_media_presence }
      end
    end

    def agency_stability_col(table)
      if @partials_to_show.include? "agency_stability"
        table["Year Founded"] = ->(partner) { partner.profile.founded }
        table["Form 990 Filed"] = ->(partner) { partner.profile.form_990 }
        table["Program Name"] = ->(partner) { partner.profile.program_name }
        table["Program Description"] = ->(partner) { partner.profile.program_description }
        table["Agency Age"] = ->(partner) { partner.profile.program_age }
        table["Evidence Based"] = ->(partner) { partner.profile.evidence_based }
        table["Case Management"] = ->(partner) { partner.profile.case_management }
        table["How Are Essentials Used"] = ->(partner) { partner.profile.essentials_use }
        table["Receive Essentials From Other Sources"] = ->(partner) { partner.profile.receives_essentials_from_other }
        table["Currently Providing Diapers"] = ->(partner) { partner.profile.currently_provide_diapers }
      end
    end

    def organizational_capacity_col(table)
      if @partials_to_show.include? "organizational_capacity"
        table["Client Capacity"] = ->(partner) { partner.profile.client_capacity }
        table["Storage Space"] = ->(partner) { partner.profile.storage_space }
        table["Storage Space Description"] = ->(partner) { partner.profile.describe_storage_space }
      end
    end

    def sources_of_funding_col(table)
      if @partials_to_show.include? "sources_of_funding"
        table["Sources Of Funding"] = ->(partner) { partner.profile.sources_of_funding }
        table["How do you currently obtain diapers?"] = ->(partner) { partner.profile.sources_of_diapers }
        table["Essentials Budget"] = ->(partner) { partner.profile.essentials_budget }
        table["Essentials Funding Source"] = ->(partner) { partner.profile.essentials_funding_source }
      end
    end

    def area_served_col(table)
      if @partials_to_show.include? "area_served"
        table["Area Served"] = ->(partner) { county_list_by_regions[partner.id] || "" }
      end
    end

    def population_served_col(table)
      if @partials_to_show.include? "population_served"
        table["Income Requirement"] = ->(partner) { partner.profile.income_requirement_desc }
        table["Verify Income"] = ->(partner) { partner.profile.income_verification }
        table["% African American"] = ->(partner) { partner.profile.population_black }
        table["% Caucasian"] = ->(partner) { partner.profile.population_white }
        table["% Hispanic"] = ->(partner) { partner.profile.population_hispanic }
        table["% Asian"] = ->(partner) { partner.profile.population_asian }
        table["% American Indian"] = ->(partner) { partner.profile.population_american_indian }
        table["% Pacific Island"] = ->(partner) { partner.profile.population_island }
        table["% Multi-racial"] = ->(partner) { partner.profile.population_multi_racial }
        table["% Other"] = ->(partner) { partner.profile.population_other }
        table["Zip Codes Served"] = ->(partner) { partner.profile.zips_served }
        table["% At FPL or Below"] = ->(partner) { partner.profile.at_fpl_or_below }
        table["% Above 1-2 times FPL"] = ->(partner) { partner.profile.above_1_2_times_fpl }
        table["% Greater than 2 times FPL"] = ->(partner) { partner.profile.greater_2_times_fpl }
        table["% Poverty Unknown"] = ->(partner) { partner.profile.poverty_unknown }
      end
    end

    def executive_director_col(table)
      if @partials_to_show.include? "executive_director"
        table["Executive Director Name"] = ->(partner) { partner.profile.executive_director_name }
        table["Executive Director Phone"] = ->(partner) { partner.profile.executive_director_phone }
        table["Executive Director Email"] = ->(partner) { partner.profile.executive_director_email }
        table["Primary Contact Name"] = ->(partner) { partner.profile.primary_contact_name }
        table["Primary Contact Phone"] = ->(partner) { partner.profile.primary_contact_phone }
        table["Primary Contact Cell"] = ->(partner) { partner.profile.primary_contact_mobile }
        table["Primary Contact Email"] = ->(partner) { partner.profile.primary_contact_email }
      end
    end

    def pick_up_person_col(table)
      if @partials_to_show.include? "pick_up_person"
        table["Pick Up Person Name"] = ->(partner) { partner.profile.pick_up_name }
        table["Pick Up Person Phone"] = ->(partner) { partner.profile.pick_up_phone }
        table["Pick Up Person Email"] = ->(partner) { partner.profile.pick_up_email }
      end
    end

    def agency_distribution_information_col(table)
      if @partials_to_show.include? "agency_distribution_information"
        table["Distribution Times"] = ->(partner) { partner.profile.distribution_times }
        table["New Client Times"] = ->(partner) { partner.profile.new_client_times }
        table["More Docs Required"] = ->(partner) { partner.profile.more_docs_required }
      end
    end

    def headers
      base_table.keys
    end

    def build_row_data(partner)
      base_table.values.map { |closure| closure.call(partner) }.map(&normalize_csv_attribute)
    end

    def normalize_csv_attribute
      ->(attr) { attr.is_a?(Array) ? attr.join(",") : attr.to_s }
    end

    # Returns a hash with partner ids as keys and served county names
    # joined by semi-colons as values.
    #
    # @return [Hash<Integer, String>]
    def county_list_by_regions
      return @county_list_by_regions if @county_list_by_regions

      @county_list_by_regions =
        partners
          .joins(profile: :counties)
          .group(:id)
          .pluck(Arel.sql("partners.id, STRING_AGG(counties.name, '; ' ORDER BY counties.region, counties.name) AS county_list"))
          .to_h
    end

    # Returns a hash with partner ids as keys with "Y" 's as values
    # The hash has a default value of "N" so partner ids not in hash will return "N"
    #
    # @return [Hash<Integer, String>]
    def diaper_statuses
      return @diaper_statuses if @diaper_statuses

      @diaper_statuses = Hash.new("N")
      partners.unscope(:order).joins(:distributions).merge(Distribution.in_last_12_months.with_diapers).distinct.ids.each do |id|
        @diaper_statuses[id] = "Y"
      end
      @diaper_statuses
    end

    # Returns a hash with partner ids as keys with "Y" 's as values
    # The hash has a default value of "N" so partner ids not in hash will return "N"
    #
    # @return [Hash<Integer, String>]
    def period_supplies_statuses
      return @period_supplies_statuses if @period_supplies_statuses

      @period_supplies_statuses = Hash.new("N")
      partners.unscope(:order).joins(:distributions).merge(Distribution.in_last_12_months.with_period_supplies).distinct.ids.each do |id|
        @period_supplies_statuses[id] = "Y"
      end
      @period_supplies_statuses
    end
  end
end
