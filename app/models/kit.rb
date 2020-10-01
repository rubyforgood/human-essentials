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

  scope :active, -> { where(active: true) }
  scope :alphabetized, -> { order(:name) }
  scope :by_partner_key, ->(key) { joins(:items).where(items: { partner_key: key }) }

  validates :organization, :name, presence: true
  validates :name, uniqueness: { scope: :organization }
  validate :at_least_one_item

  private

  def at_least_one_item
    unless line_items.any?
      errors.add(:base, 'At least one item is required')
    end
  end
end
