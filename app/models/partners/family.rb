# == Schema Information
#
# Table name: families
#
#  id                        :bigint           not null, primary key
#  archived                  :boolean          default(FALSE)
#  case_manager              :string
#  comments                  :text
#  guardian_county           :string
#  guardian_employed         :boolean
#  guardian_employment_type  :jsonb
#  guardian_first_name       :string
#  guardian_health_insurance :jsonb
#  guardian_last_name        :string
#  guardian_monthly_pay      :decimal(, )
#  guardian_phone            :string
#  guardian_zip_code         :string
#  home_adult_count          :integer
#  home_child_count          :integer
#  home_young_child_count    :integer
#  military                  :boolean          default(FALSE)
#  sources_of_income         :jsonb
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  old_partner_id            :bigint
#  partner_id                :bigint
#
module Partners
  class Family < Base
    has_paper_trail
    belongs_to :partner, class_name: '::Partner'
    has_many :children, dependent: :destroy
    has_many :authorized_family_members, dependent: :destroy
    serialize :sources_of_income, type: Array
    validates :guardian_first_name, :guardian_last_name, :guardian_zip_code, presence: true

    include Filterable
    include Exportable

    filterrific(
      available_filters: [
        :search_guardian_names,
        :search_agency_guardians,
        :include_archived
      ],
    )

    scope :search_guardian_names, ->(query) { where('guardian_first_name ilike ? OR guardian_last_name ilike ?', "%#{query}%", "%#{query}%") }
    scope :search_agency_guardians, ->(query) { where('case_manager ilike ?', "%#{query}%") }
    scope :include_archived, ->(archived) {
      return where(archived: false) if archived == 0
      all
    }

    INCOME_TYPES = ['SSI', 'SNAP/FOOD Stamps', 'TANF', 'WIC', 'Housing/subsidized', 'Housing/unsubsidized', 'N/A'].freeze
    INSURANCE_TYPES = ['Private insurance', 'Medicaid', 'Uninsured'].freeze
    EMPLOYMENT_TYPES = %w[Full-time Part-time N/A].freeze

    after_create :create_authorized

    def create_authorized
      authorized_family_members.create!(
        first_name: guardian_first_name,
        last_name: guardian_last_name
      )
    end

    def guardian_display_name
      "#{guardian_first_name} #{guardian_last_name}"
    end

    def total_children_count
      home_child_count + home_young_child_count
    end

    def self.csv_export_headers
      %w[
        id guardian_first_name guardian_last_name guardian_zip_code guardian_county
        guardian_phone case_manager home_adult_count home_child_count home_young_child_count
        sources_of_income guardian_employed guardian_employment_type guardian_monthly_pay
        guardian_health_insurance comments created_at updated_at partner_id military archived
      ].freeze
    end

    def csv_export_attributes
      [
        id,
        guardian_first_name,
        guardian_last_name,
        guardian_zip_code,
        guardian_county,
        guardian_phone,
        case_manager,
        home_adult_count,
        home_child_count,
        home_young_child_count,
        sources_of_income,
        guardian_employed,
        guardian_employment_type,
        guardian_monthly_pay,
        guardian_health_insurance,
        comments,
        created_at,
        updated_at,
        partner_id,
        military,
        archived
      ]
    end
  end
end

