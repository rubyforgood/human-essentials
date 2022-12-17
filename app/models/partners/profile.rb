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
#  application_data               :text
#  at_fpl_or_below                :integer
#  case_management                :boolean
#  city                           :string
#  client_capacity                :string
#  currently_provide_diapers      :boolean
#  describe_storage_space         :text
#  distribution_times             :string
#  distributor_type               :string
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
#  partner_status                 :string           default("pending")
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
    self.table_name = "partner_profiles"
    belongs_to :partner
    has_one :organization, through: :partner, class_name: "::Organization"

    has_one_attached :proof_of_partner_status
    has_one_attached :proof_of_form_990

    has_many :served_areas, foreign_key: "partner_profile_id", class_name: "Partners::ServedArea", dependent: :destroy, inverse_of: :partner_profile

    accepts_nested_attributes_for :served_areas, allow_destroy: true

    has_many_attached :documents

    validates :no_social_media_presence, acceptance: {message: "must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram."}, if: :has_no_social_media?

    validate :client_share_is_0_or_100

    self.ignored_columns = %w[
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

    def has_no_social_media?
      website.blank? && twitter.blank? && facebook.blank? && instagram.blank?
    end

    def client_share_total
      tot = 0
      served_areas.each do |served_area|
        tot += served_area.client_share
      end
      tot
    end

    def client_share_is_0_or_100
      value = client_share_total
      check = (value == 0 || value == 100)
      if !check
        errors.add(:base, "Total client share must be 0 or 100")
      end
      check
    end
  end
end
