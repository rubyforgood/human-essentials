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
  include Filterable

  validates :from, :to, :organization, presence: true
  validates_associated :line_items
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
