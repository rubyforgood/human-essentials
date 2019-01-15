# == Schema Information
#
# Table name: audits
#
#  id                  :bigint(8)        not null, primary key
#  user_id             :bigint(8)
#  organization_id     :bigint(8)
#  adjustment_id       :bigint(8)
#  storage_location_id :bigint(8)
#  status              :integer          default("in_progress"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Audit < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :storage_location
  belongs_to :adjustment, optional: true

  include Itemizable
  include Filterable
  scope :at_location, ->(location_id) { where(storage_location_id: location_id) }

  accepts_nested_attributes_for :adjustment

  enum status: { in_progress: 0, confirmed: 1, finalized: 2 }

  validates :storage_location, :organization, presence: true
  validate :line_item_items_exist_in_inventory
  validate :line_item_items_quantity_is_positive
  validate :user_is_organization_admin_of_the_organization

  def self.storage_locations_audited_for(organization)
    includes(:storage_location).where(organization_id: organization.id).collect(&:storage_location)
  end

  def user_is_organization_admin_of_the_organization
    return if organization.nil?

    unless organization.users.include?(user) && user.organization_admin
      errors.add :user, "user must be an organization admin of the organization"
    end
  end
end
