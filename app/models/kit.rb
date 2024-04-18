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
  has_paper_trail
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

  validates :name, presence: true
  validates :name, uniqueness: { scope: :organization }

  validate :at_least_one_item
  validate -> { line_items_quantity_is_at_least(1) }

  # @param inventory [View::Inventory]
  # @return [Boolean]
  def can_deactivate?(inventory)
    if inventory
      inventory.quantity_for(item_id: item.id).zero?
    else
      inventory_items.where('quantity > 0').none?
    end
  end

  def deactivate
    update!(active: false)
    item.update!(active: false)
  end

  # Kits can't reactivate if they have any inactive items, because now whenever they are allocated
  # or deallocated, we are changing inventory for inactive items (which we don't allow).
  # @return [Boolean]
  def can_reactivate?
    line_items.joins(:item).where(items: { active: false }).none?
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
