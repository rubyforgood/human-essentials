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

  include Itemizable
  alias_attribute :storage_location, :from # to make it play nice with Itemizable
  include Filterable
  scope :from_location, ->(location_id) { where(from_id: location_id) }
  scope :to_location, ->(location_id) { where(to_id: location_id) }

  # TODO: This query could probably be made more...better
  def self.storage_locations_transferred_to_in(organization)
    self.includes(:to).where(organization_id: organization.id).distinct(:to_id).collect do |xfer|
      xfer.to
    end.uniq
  end

  # TODO: This query could probably be made more...better
  def self.storage_locations_transferred_from_in(organization)
    self.includes(:from).where(organization_id: organization.id).distinct(:from_id).collect do |xfer|
      xfer.from
    end.uniq
  end


  validates :from, :to, :organization, presence: true
  validate :line_item_items_exist_in_inventory
  validate :storage_locations_belong_to_organization

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
end
