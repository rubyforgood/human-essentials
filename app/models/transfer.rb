# == Schema Information
#
# Table name: transfers
#
#  id              :integer          not null, primary key
#  from_id         :integer
#  to_id           :integer
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

class Transfer < ApplicationRecord
  belongs_to :organization
  belongs_to :from, :class_name => 'StorageLocation', :foreign_key => :from_id
  belongs_to :to, :class_name => 'StorageLocation', :foreign_key => :to_id

  has_many :line_items, as: :itemizable, inverse_of: :itemizable
  has_many :items, through: :line_items
  accepts_nested_attributes_for :line_items,
    allow_destroy: true,
    :reject_if => proc { |li| li[:item_id].blank? || li[:quantity].blank? }

  validates :from, :to, :organization, presence: true
  validates_associated :line_items
  validate :line_item_items_exist_in_inventory
  validate :storage_locations_belong_to_organization

  # TODO - this could probably be made an association method for the `line_items` association
  def quantities_by_category
    line_items.includes(:item).group("items.category").sum(:quantity)
  end

  # TODO - this could probably be made an association method for the `line_items` association
  def sorted_line_items
    line_items.includes(:item).order("items.name")
  end

  # TODO - this could probably be made an association method for the `line_items` association
  def total_quantity
    line_items.sum(:quantity)
  end

  private

  def storage_locations_belong_to_organization
    return if self.organization.nil?

    if !self.organization.storage_locations.include?(self.from)
      errors.add :from, 'from location must belong to organization'
    end

    if !self.organization.storage_locations.include?(self.to)
      errors.add :to, 'to location must belong to organization'
    end
  end

  # TODO - this could probably be made an association method for the `line_items` association
  def line_item_items_exist_in_inventory
    self.line_items.each do |line_item|
      next unless line_item.item
      inventory_item = self.from.inventory_items.find_by(item: line_item.item)
      if inventory_item.nil?
        errors.add(:inventory,
                   "#{line_item.item.name} is not available " \
                   "at this storage location")
      end
    end
  end
end
