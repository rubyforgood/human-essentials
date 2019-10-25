# == Schema Information
#
# Table name: diaper_drives
#
#  id         :bigint(8)        not null, primary key
#  name       :string
#  start_date :date
#  end_date   :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class DiaperDrive < ApplicationRecord
  belongs_to :organization, optional: true
  has_many :donations, dependent: :nullify
  validates :name, presence:
    { message: "A name must be chosen." }
  validates :start_date, presence:
    { message: "Please enter a start date." }
  scope :alphabetized, -> { order(:name) }

  def donation_quantity
    donations.joins(:line_items).count('line_items.quantity')
  end

  def distinct_items
    donations.joins(:items).distinct(:item_id).count
  end

  def in_kind_value
    donations.count(&:value_per_itemizable)
  end
end
