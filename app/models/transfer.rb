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

  def self.storage_locations_transferred_to_in(organization)
    includes(:to).where(organization_id: organization.id).distinct(:to_id).collect(&:to).uniq.sort_by(&:name)
  end

  def self.storage_locations_transferred_from_in(organization)
    includes(:from).where(organization_id: organization.id).distinct(:from_id).collect(&:from).uniq.sort_by(&:name)
  end

  validates :from, :to, :organization, presence: true
  validate :line_item_items_exist_in_inventory
  validate :storage_locations_belong_to_organization

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
      errors.add :from, "from location must belong to organization"
    end

    unless organization.storage_locations.include?(to)
      errors.add :to, "to location must belong to organization"
    end
  end
end
