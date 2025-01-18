class ConvertPartnerAgencyTypesToEnum < ActiveRecord::Migration[7.2]
  def up
    # A mapping from the lowercase full descriptive strings previously stored in
    # agency_type to the newly enumerated values
    string_to_value_mapping = {
      "other" => "OTHER",
      "career technical training" => "CAREER",
      "child abuse resource center" => "ABUSE",
      "basic needs bank" => "BNB",
      "church outreach ministry" => "CHURCH",
      "college and universities" => "COLLEGE",
      "community development corporation" => "CDC",
      "community health program or clinic" => "HEALTH",
      "community outreach services" => "OUTREACH",
      "correctional facilities / jail / prison / legal system" => "LEGAL",
      "crisis/disaster services" => "CRISIS",
      "developmental disabilities program" => "DISAB",
      "school district" => "DISTRICT",
      "domestic violence shelter" => "DOMV",
      "early childhood education/childcare" => "ECE",
      "early childhood services" => "CHILD",
      "education program" => "EDU",
      "family resource center" => "FAMILY",
      "food bank/pantry" => "FOOD",
      "foster program" => "FOSTER",
      "government agency/affiliate" => "GOVT",
      "head start/early head start" => "HEADSTART",
      "home visits" => "HOMEVISIT",
      "homeless resource center" => "HOMELESS",
      "hospital" => "HOSP",
      "infant/child pantry/closet" => "INFPAN",
      "library" => "LIB",
      "mental health" => "MHEALTH",
      "military bases/veteran services" => "MILITARY",
      "police station" => "POLICE",
      "pregnancy resource center" => "PREG",
      "preschool" => "PRESCH",
      "refugee resource center" => "REF",
      "school - elementary school" => "ES",
      "school - high school" => "HS",
      "school - middle school" => "MS",
      "senior center" => "SENIOR",
      "tribal/native-based organization" => "TRIBAL",
      "treatment clinic" => "TREAT",
      "two-year college" => "2YCOLLEGE",
      "women, infants and children" => "WIC"
    }

    # Some agency types have trailing spaces -- need to get rid of them first
    update "UPDATE partner_profiles SET agency_type = TRIM(agency_type);"

    Partners::Profile.all.find_each do |profile|
      # Read the agency_type without casting so values not part of the enum aren't
      # read as nil
      current_agency_type = profile.read_attribute_before_type_cast(:agency_type)
      if current_agency_type.present?
        # If a profile has a descriptive string (ignoring case) as an agency type
        # update it to the associated value code.
        if string_to_value_mapping.key?(current_agency_type.downcase)
          profile.agency_type = string_to_value_mapping[current_agency_type.downcase]
        # If a profile has a value code (ignoring case) as an agency type, uppercase it.
        elsif string_to_value_mapping.value?(current_agency_type.upcase)
          profile.agency_type = current_agency_type.upcase
        end
        profile.save!
      end
    end
  end

  def down
    # Irreversible data migration
  end
end
