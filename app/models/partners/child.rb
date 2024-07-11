# == Schema Information
#
# Table name: children
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  archived             :boolean
#  child_lives_with     :jsonb
#  comments             :text
#  date_of_birth        :date
#  first_name           :string
#  gender               :string
#  health_insurance     :jsonb
#  item_needed_diaperid :integer
#  last_name            :string
#  race                 :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  agency_child_id      :string
#  family_id            :bigint
#
module Partners
  class Child < Base
    has_paper_trail
    serialize :child_lives_with, type: Array
    belongs_to :family
    has_many :child_item_requests, dependent: :destroy
    has_and_belongs_to_many :requested_items, class_name: 'Item'

    include Filterable
    include Exportable

    scope :from_family, ->(family_id) {
      where(family_id: family_id)
    }
    scope :from_children, ->(chidren_id) {
      where(id: chidren_id)
    }
    scope :active, -> { where(active: true) }

    filterrific(
      available_filters: [
        :search_names,
        :search_families,
        :search_active
      ],
    )

    scope :search_names, ->(query) { where('first_name ilike ? OR last_name ilike ?', "%#{query}%", "%#{query}%") }
    scope :search_active, ->(query) { query.zero? ? nil : where(active: true) }
    scope :search_families, ->(query) {
      where("concat_ws(' ', families.guardian_first_name, families.guardian_last_name) ILIKE ?", "%#{query}%")
    }

    CAN_LIVE_WITH = ['Mother', 'Father', 'Grandparent', 'Foster Parent', 'Other Parent/Relative'].freeze
    RACES = ['African American', 'Caucasian', 'Hispanic', 'Asian', 'American Indian', 'Pacific Islander', 'Multi-racial', 'Other'].freeze
    CHILD_ITEMS = ["Bed Pads (Cloth)",
                   "Bed Pads (Disposable)",
                   "Bibs (Adult & Child)",
                   "Cloth Diapers (AIO's/Pocket)",
                   "Cloth Diapers (Covers)",
                   "Cloth Diapers (Plastic Cover Pants)",
                   "Cloth Diapers (Prefolds & Fitted)",
                   "Cloth Inserts (For Cloth Diapers)",
                   "Cloth Potty Training Pants/Underwear",
                   "Cloth Swimmers (Kids)",
                   "Diaper Rash Cream/Powder",
                   "Disposable Inserts",
                   "Kids (Newborn)",
                   "Kids (Preemie)",
                   "Kids (Size 1)",
                   "Kids (Size 2)",
                   "Kids (Size 3)",
                   "Kids (Size 4)",
                   "Kids (Size 5)",
                   "Kids (Size 6)",
                   "Kids (Size 7)",
                   "Kids S/M (38-65 lbs)",
                   "Kids L/XL (60-125 lbs)",
                   "Kids Pull-Ups (2T-3T)",
                   "Kids Pull-Ups (3T-4T)",
                   "Kids Pull-Ups (4T-5T)",
                   "Other Wipes (Baby)"].freeze

    def display_name
      "#{first_name} #{last_name}"
    end

    def self.csv_export_headers
      %w[
        id first_name last_name date_of_birth gender child_lives_with race agency_child_id
        health_insurance comments created_at updated_at family_id requested_item_ids active archived
      ].freeze
    end

    def csv_export_attributes
      [
        id,
        first_name,
        last_name,
        date_of_birth,
        gender,
        child_lives_with,
        race,
        agency_child_id,
        health_insurance,
        comments,
        created_at,
        updated_at,
        family_id,
        requested_item_ids,
        active,
        archived
      ]
    end
  end
end

