# == Schema Information
#
# Table name: partner_profiles
#
#  id                             :bigint           not null, primary key
#  above_1_2_times_fpl            :integer
#  address1                       :string
#  address2                       :string
#  agency_mission                 :text
#  agency_type                    :string
#  at_fpl_or_below                :integer
#  case_management                :boolean
#  city                           :string
#  client_capacity                :string
#  currently_provide_diapers      :boolean
#  describe_storage_space         :text
#  distribution_times             :string
#  enable_child_based_requests    :boolean          default(TRUE), not null
#  enable_individual_requests     :boolean          default(TRUE), not null
#  enable_quantity_based_requests :boolean          default(TRUE), not null
#  essentials_budget              :string
#  essentials_funding_source      :string
#  essentials_use                 :string
#  evidence_based                 :boolean
#  executive_director_email       :string
#  executive_director_name        :string
#  executive_director_phone       :string
#  facebook                       :string
#  form_990                       :boolean
#  founded                        :integer
#  greater_2_times_fpl            :integer
#  income_requirement_desc        :boolean
#  income_verification            :boolean
#  instagram                      :string
#  more_docs_required             :string
#  name                           :string
#  new_client_times               :string
#  no_social_media_presence       :boolean
#  other_agency_type              :string
#  pick_up_email                  :string
#  pick_up_name                   :string
#  pick_up_phone                  :string
#  population_american_indian     :integer
#  population_asian               :integer
#  population_black               :integer
#  population_hispanic            :integer
#  population_island              :integer
#  population_multi_racial        :integer
#  population_other               :integer
#  population_white               :integer
#  poverty_unknown                :integer
#  primary_contact_email          :string
#  primary_contact_mobile         :string
#  primary_contact_name           :string
#  primary_contact_phone          :string
#  program_address1               :string
#  program_address2               :string
#  program_age                    :string
#  program_city                   :string
#  program_description            :text
#  program_name                   :string
#  program_state                  :string
#  program_zip_code               :integer
#  receives_essentials_from_other :string
#  sources_of_diapers             :string
#  sources_of_funding             :string
#  state                          :string
#  status_in_diaper_base          :string
#  storage_space                  :boolean
#  twitter                        :string
#  website                        :string
#  zip_code                       :string
#  zips_served                    :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  essentials_bank_id             :bigint
#  partner_id                     :integer
#
module Partners
  class Profile < Base
    has_paper_trail
    self.table_name = "partner_profiles"
    belongs_to :partner
    has_one :organization, through: :partner, class_name: "::Organization"

    has_one_attached :proof_of_partner_status
    has_one_attached :proof_of_form_990

    has_many :served_areas, foreign_key: "partner_profile_id", class_name: "Partners::ServedArea", dependent: :destroy, inverse_of: :partner_profile

    has_many :counties, through: :served_areas
    accepts_nested_attributes_for :served_areas, allow_destroy: true

    has_many_attached :documents
    enum :agency_type,
      other: "OTHER",
      career: "CAREER",
      abuse: "ABUSE",
      bnb: "BNB",
      church: "CHURCH",
      college: "COLLEGE",
      cdc: "CDC",
      health: "HEALTH",
      outreach: "OUTREACH",
      legal: "LEGAL",
      crisis: "CRISIS",
      disab: "DISAB",
      district: "DISTRICT",
      domv: "DOMV",
      ece: "ECE",
      child: "CHILD",
      edu: "EDU",
      family: "FAMILY",
      food: "FOOD",
      foster: "FOSTER",
      govt: "GOVT",
      headstart: "HEADSTART",
      homevisit: "HOMEVISIT",
      homeless: "HOMELESS",
      hosp: "HOSP",
      infpan: "INFPAN",
      lib: "LIB",
      mhealth: "MHEALTH",
      military: "MILITARY",
      police: "POLICE",
      preg: "PREG",
      presch: "PRESCH",
      ref: "REF",
      es: "ES",
      hs: "HS",
      ms: "MS",
      senior: "SENIOR",
      tribal: "TRIBAL",
      treat: "TREAT",
      twoycollege: "2YCOLLEGE",
      wic: "WIC"

    validate :check_social_media, on: :edit

    validate :client_share_is_0_or_100
    validate :has_at_least_one_request_setting
    validate :pick_up_email_addresses

    # For the sake of documentation, here are the partials each field belongs to. In the order those
    # partials appear in the actual form.
    # agency_information -- this partial is always shown, contains the agency information AND the Program / Delivery Address sections of the form
    #   agency_type, other_agency_type, agency_mission, address1, address2, city, state, zip_code,
    #   program_address1, program_address2, program_city, program_state, program_zip_code
    # media_information
    #   website, facebook, twitter, instagram, no_social_media_presence
    # agency_stability
    #   founded, form_990, program_name, program_description, program_age, evidence_based, case_management,
    #   essentials_use, receives_essentials_from_other, currently_provide_diapers
    # organizational_capacity
    #   client_capacity, storage_space, describe_storage_space
    # sources_of_funding
    #   sources_of_funding, sources_of_diapers, essentials_budget, essentials_funding_source
    # area_served
    #   has no associated Partners::Profile fields
    # population_served
    #   income_requirement_desc, income_verification, population_black, population_white,
    #   population_hispanic, population_asian, population_american_indian, population_island,
    #   population_multi_racial, population_other, zips_served, at_fpl_or_below, above_1_2_times_fpl
    #   greater_2_times_fpl, poverty_unknown
    # contacts
    #   executive_director_name, executive_director_phone, executive_director_email, primary_contact_name,
    #   primary_contact_phone, primary_contact_mobile, primary_contact_email
    # pick_up_person
    #   pick_up_name, pick_up_phone, pick_up_email
    # agency_distribution_information
    #   distribution_times, new_client_times, more_docs_required
    # attached_documents
    #   has no associated Partners::Profile fields
    # partner_settings -- this partial is always shown
    #   enable_quantity_based_requests, enable_child_based_requests, enable_individual_requests

    # These are columns which currently do not appear in any partial of the profile form.
    # It is possible these will be removed in the future.
    self.ignored_columns += %w[
      application_data
      distributor_type
      evidence_based_description
      program_client_improvement
      incorporate_plan
      turn_away_child_care
      responsible_staff_position
      trusted_pickup
      serve_income_circumstances
      internal_db
      maac
      pick_up_method
      ages_served
    ]

    def client_share_total
      # client_share could be nil
      served_areas.map(&:client_share).compact.sum
    end

    def split_pick_up_emails
      return nil if pick_up_email.nil?

      pick_up_email.split(/,|\s+/).compact_blank
    end

    def self.agency_types_for_selection
      # alphabetize based on the translated version, as that is the text users will actually read
      agency_types.keys.map(&:to_sym).sort_by { |sym| I18n.t(sym, scope: :partners_profile) }.partition { |v| v != :other }.flatten
    end

    private

    def check_social_media
      return if website.present? || twitter.present? || facebook.present? || instagram.present?
      return if partner.partials_to_show.exclude?("media_information")

      unless no_social_media_presence
        errors.add(:no_social_media_presence, "must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.")
      end
    end

    def client_share_is_0_or_100
      # business logic:  the client share has to be 0 or 100 -- although it is an estimate only,  making it 0 (not
      # specified at all) or 100 means we won't have people overallocating (> 100) and that they think about what
      # their allocation actually is
      total = client_share_total
      if total != 0 && total != 100
        if Flipper.enabled?("partner_step_form")
          # need to set errors on specific fields within the form so that it can be mapped to a section
          errors.add(:client_share, "Total client share must be 0 or 100")
        else
          errors.add(:base, "Total client share must be 0 or 100")
        end
      end
    end

    def has_at_least_one_request_setting
      if !(enable_child_based_requests || enable_individual_requests || enable_quantity_based_requests)
        if Flipper.enabled?("partner_step_form")
          # need to set errors on specific fields within the form so that it can be mapped to a section
          errors.add(:enable_child_based_requests, "At least one request type must be set")
        else
          errors.add(:base, "At least one request type must be set")
        end
      end
    end

    def pick_up_email_addresses
      # pick_up_email is a string of comma-separated emails, check specs for details
      return if pick_up_email.nil?

      emails = split_pick_up_emails
      if emails.size > 3
        errors.add(:pick_up_email, "can't have more than three email addresses")
        nil
      end
      if emails.uniq.size != emails.size
        errors.add(:pick_up_email, "should not have repeated email addresses")
      end
      emails.each do |e|
        errors.add(:pick_up_email, "is invalid") unless e.match? URI::MailTo::EMAIL_REGEXP
      end
    end
  end
end
