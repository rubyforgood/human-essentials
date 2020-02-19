# == Schema Information
#
# Table name: transfers
#
#  id              :bigint           not null, primary key
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  from_id         :integer
#  organization_id :integer
#  to_id           :integer
#

class Transfer < ApplicationRecord
  belongs_to :organization, inverse_of: :transfers
  belongs_to :from, class_name: "StorageLocation", foreign_key: :from_id,
                    inverse_of: :transfers_from
  belongs_to :to, class_name: "StorageLocation", foreign_key: :to_id, inverse_of: :transfers_to

  include Itemizable
  alias_attribute :storage_location, :from # to make it play nice with Itemizable
  include Filterable
  scope :from_location, ->(location_id) { where(from_id: location_id) }
  scope :to_location, ->(location_id) { where(to_id: location_id) }
  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .includes(:line_items, :from, :to)
  }
  scope :during, ->(range) { where(created_at: range) }

  def self.storage_locations_transferred_to_in(organization)
    includes(:to).where(organization_id: organization.id).distinct(:to_id).collect(&:to).uniq.sort_by(&:name)
  end

  def self.storage_locations_transferred_from_in(organization)
    includes(:from).where(organization_id: organization.id).distinct(:from_id).collect(&:from).uniq.sort_by(&:name)
  end

  validates :from, :to, :organization, presence: true
  validate :line_item_items_exist_in_inventory
  validate :storage_locations_belong_to_organization
  validate :storage_locations_must_be_different
  validate :from_storage_locations_must_have_enough_to_transfer_out

  def self.csv_export_headers
    ["From", "To", "Comment", "Total Moved"]
  end

  def csv_export_attributes
    [
      from.name,
      to.name,
      comment || "none",
      line_items.total
    ]
  end

  private

  def storage_locations_belong_to_organization
    return if organization.nil?

    unless organization.storage_locations.include?(from)
      errors.add :from, "location must belong to organization"
    end

    unless organization.storage_locations.include?(to)
      errors.add :to, "location must belong to organization"
    end
  end

  def storage_locations_must_be_different
    return if organization.nil? || to_id.nil?

    if from_id == to_id
      errors.add :to, "location must be different than from location"
    end
  end

  def from_storage_locations_must_have_enough_to_transfer_out
    return if organization.nil? || from.nil?

    inventory_items = from.inventory_items.each_with_object({}) do |inventory_item, memo|
      memo[inventory_item.item_id] = inventory_item.quantity
    end
    insufficient_items = []
    line_items.each do |line_item|
      if line_item.quantity > inventory_items.fetch(line_item.item_id, 0)
        insufficient_items << line_item.item.name
      end
    end
    if insufficient_items.any?
      errors.add :from, "location has insufficient inventory for #{insufficient_items.join(', ')}"
    end
  end
end
