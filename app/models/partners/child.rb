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
    CAN_LIVE_WITH = %w[Mother Father Grandparent Foster\ Parent Other\ Parent/Relative].freeze
    RACES = %w[African\ American Caucasian Hispanic Asian American\ Indian Pacific\ Islander Multi-racial Other].freeze
    CHILD_ITEMS = [
      "Bed Pads (Cloth)",
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
      "Other Wipes (Baby)"
    ].freeze
    belongs_to :family
    has_many :child_item_requests, dependent: :destroy
  end
end

