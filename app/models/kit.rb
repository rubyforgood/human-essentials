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
  has_one :item, dependent: :restrict_with_exception
  has_many :inventory_items, through: :item

  scope :active, -> { where(active: true) }
  scope :alphabetized, -> { order(:name) }
  scope :by_partner_key, ->(key) { joins(:items).where(items: { partner_key: key }) }
  scope :by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }

  validates :organization, :name, presence: true
  validates :name, uniqueness: { scope: :organization }

  validate :at_least_one_item

  # @return [Boolean]
  def can_deactivate?
    inventory_items.where('quantity > 0').none?
  end

  def deactivate
    update!(active: false)
    item.update!(active: false)
  end

  def reactivate
    update!(active: true)
    item.update!(active: true)
  end

  private

  def at_least_one_item
    unless line_items.any?
      errors.add(:base, 'At least one item is required')
    end
  end
end
