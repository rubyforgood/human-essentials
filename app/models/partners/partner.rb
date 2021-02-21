# == Schema Information
#
# Table name: partners
#
#  id                         :bigint           not null, primary key
#  above_1_2_times_fpl        :integer
#  address1                   :string
#  address2                   :string
#  agency_mission             :text
#  agency_type                :string
#  ages_served                :string
#  application_data           :text
#  at_fpl_or_below            :integer
#  case_management            :boolean
#  city                       :string
#  currently_provide_diapers  :boolean
#  describe_storage_space     :text
#  diaper_budget              :string
#  diaper_funding_source      :string
#  diaper_use                 :string
#  distribution_times         :string
#  distributor_type           :string
#  evidence_based             :boolean
#  evidence_based_description :text
#  executive_director_email   :string
#  executive_director_name    :string
#  executive_director_phone   :string
#  facebook                   :string
#  form_990                   :boolean
#  founded                    :integer
#  greater_2_times_fpl        :integer
#  income_requirement_desc    :boolean
#  income_verification        :boolean
#  incorporate_plan           :text
#  internal_db                :boolean
#  maac                       :boolean
#  max_serve                  :string
#  more_docs_required         :string
#  name                       :string
#  new_client_times           :string
#  other_agency_type          :string
#  other_diaper_use           :string
#  partner_status             :string           default("pending")
#  pick_up_email              :string
#  pick_up_method             :string
#  pick_up_name               :string
#  pick_up_phone              :string
#  population_american_indian :integer
#  population_asian           :integer
#  population_black           :integer
#  population_hispanic        :integer
#  population_island          :integer
#  population_multi_racial    :integer
#  population_other           :integer
#  population_white           :integer
#  poverty_unknown            :integer
#  program_address1           :string
#  program_address2           :string
#  program_age                :string
#  program_city               :string
#  program_client_improvement :text
#  program_contact_email      :string
#  program_contact_mobile     :string
#  program_contact_name       :string
#  program_contact_phone      :string
#  program_description        :text
#  program_name               :string
#  program_state              :string
#  program_zip_code           :integer
#  responsible_staff_position :boolean
#  serve_income_circumstances :boolean
#  sources_of_diapers         :string
#  sources_of_funding         :string
#  state                      :string
#  status_in_diaper_base      :string
#  storage_space              :boolean
#  trusted_pickup             :boolean
#  turn_away_child_care       :boolean
#  twitter                    :string
#  website                    :string
#  zip_code                   :string
#  zips_served                :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  diaper_bank_id             :bigint
#  diaper_partner_id          :integer
#
module Partners
  class Partner < Base
    has_one :user, dependent: :destroy
    has_many :requests, dependent: :destroy
    has_many :families, dependent: :destroy
    has_many :children, through: :families
    has_many :authorized_family_members, through: :families
    has_one :partner_form, primary_key: :diaper_bank_id, foreign_key: :diaper_bank_id, dependent: :destroy, inverse_of: :partner

    has_one_attached :proof_of_partner_status
    has_one_attached :proof_of_form_990
    has_many_attached :documents

    def verified?
      partner_status == "verified"
    end

    def organization
      Organization.find_by!(id: diaper_bank_id)
    end
  end
end

