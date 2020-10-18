# == Schema Information
#
# Table name: kits
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE)
#  name                :string           not null
#  value_in_cents      :integer          default(0)
#  visible_to_partners :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer          not null
#
class Kit < ApplicationRecord
  include Itemizable
  include Filterable
  include Valuable

  belongs_to :organization
  has_one :item
  has_many :inventory_items, through: :item

  scope :active, -> { where(active: true) }
  scope :alphabetized, -> { order(:name) }
  scope :by_partner_key, ->(key) { joins(:items).where(items: { partner_key: key }) }

  validates :organization, :name, presence: true
  validates :name, uniqueness: { scope: :organization }

  validate :at_least_one_item

  # TODO
  # - Ensure that other organizations can re-use the name for the BaseItem associated to a Kit
  # - Ensure the BaseItem for a Kit has only one Item or Kit option. We do not want to allow multiple.
  # It should be 1-to-1-to-1 relationship

  private

  def at_least_one_item
    unless line_items.any?
      errors.add(:base, 'At least one item is required')
    end
  end
end
