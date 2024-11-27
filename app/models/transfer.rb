# == Schema Information
#
# Table name: transfers
#
#  id              :integer          not null, primary key
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  from_id         :integer
#  organization_id :integer
#  to_id           :integer
#

class Transfer < ApplicationRecord
  has_paper_trail
  belongs_to :organization, inverse_of: :transfers
  belongs_to :from, class_name: "StorageLocation", inverse_of: :transfers_from
  belongs_to :to, class_name: "StorageLocation", inverse_of: :transfers_to

  include Itemizable
  include Filterable
  include Exportable
  alias_attribute :storage_location, :from # to make it play nice with Itemizable
  scope :from_location, ->(location_id) { where(from_id: location_id) }
  scope :to_location, ->(location_id) { where(to_id: location_id) }
  scope :for_csv_export, ->(organization, *) {
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
  validate :line_items_exist_in_inventory
  validate :storage_locations_belong_to_organization
  validate :storage_locations_must_be_different
  validate :from_storage_quantities

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

  def from_storage_quantities
    return if organization.nil? || from.nil?

    names = insufficient_items.map(&:name)

    if names.any?
      errors.add :from, "location has insufficient inventory for #{names.join(', ')}"
    end
  end

  def insufficient_items
    if Event.read_events?(organization)
      inventory = View::Inventory.new(organization_id)
      line_items.select { |i| i.quantity > inventory.quantity_for(item_id: i.item_id) }
    else
      line_items.select { |i| i.quantity > from.item_total(i.item_id) }
    end
  end
end
