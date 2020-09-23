# == Schema Information
#
# Table name: adjustments
#
#  id                  :integer          not null, primary key
#  comment             :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer
#  storage_location_id :integer
#  user_id             :bigint
#

class Adjustment < ApplicationRecord
  belongs_to :organization
  belongs_to :storage_location
  belongs_to :user

  include Exportable
  include Itemizable
  include Filterable
  scope :at_location, ->(location_id) { where(storage_location_id: location_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .includes(:storage_location, :line_items)
  }
  scope :during, ->(range) { where(adjustments: { created_at: range }) }

  validates :storage_location, :organization, presence: true
  validate :negative_line_item_items_exist_in_inventory
  validate :storage_locations_belong_to_organization

  def self.storage_locations_adjusted_for(organization)
    includes(:storage_location).where(organization_id: organization.id).collect(&:storage_location).sort
  end

  def split_difference
    pre_adjustment = line_items.partition { |line_item| line_item.quantity.positive? }
    increasing_adjustment, decreasing_adjustment = pre_adjustment.map { |adjustment| Adjustment.new(line_items: adjustment) }

    decreasing_adjustment.line_items.each { |line_item| line_item.quantity *= -1 }
    [increasing_adjustment, decreasing_adjustment]
  end

  def self.csv_export_headers
    ["Created", "Organization", "Storage Location", "Comment", "Changes"]
  end

  def csv_export_attributes
    [
      created_at.strftime("%F"),
      organization.name,
      storage_location.name,
      comment,
      line_items.count
    ]
  end

  private

  def storage_locations_belong_to_organization
    return if organization.nil?

    unless organization.storage_locations.include?(storage_location)
      errors.add :storage_location, "storage location must belong to organization"
    end
  end

  def negative_line_item_items_exist_in_inventory
    return if storage_location.nil?

    line_items.each do |line_item|
      next unless line_item.quantity.negative?

      inventory_item = storage_location.inventory_items.find_by(item: line_item.item)
      next unless inventory_item.nil?

      errors.add(:inventory,
                 "#{line_item.item.name} is not available to be removed from this storage location")
    end
  end
end
