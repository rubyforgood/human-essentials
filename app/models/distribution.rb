# == Schema Information
#
# Table name: distributions
#
#  id                  :integer          not null, primary key
#  comment             :text
#  created_at          :datetime
#  updated_at          :datetime
#  storage_location_id :integer
#  partner_id          :integer
#  organization_id     :integer
#  issued_at           :datetime
#

class Distribution < ApplicationRecord

  # Distributions are issued from a single storage location, so we associate
  # them so that on-hand amounts can be verified
  belongs_to :storage_location

  # Distributions are issued to a single partner
  belongs_to :partner
  belongs_to :organization

  # Distributions contain many different items
  include Itemizable

  validates :storage_location, :partner, :organization, presence: true
  # TODO Should these be added to Itemizable?
  validates_associated :line_items
  validate :line_item_items_exist_in_inventory

  include IssuedAt

  scope :recent, ->(count=3) { order(:issued_at).limit(count) }
  scope :during, ->(range) { where(distributions: { issued_at: range }) }

  delegate :name, to: :partner, prefix: true

  private
  # TODO Should this be added to Itemizable?
  def line_item_items_exist_in_inventory
    self.line_items.each do |line_item|
      next unless line_item.item
      inventory_item = self.storage_location.inventory_items.find_by(item: line_item.item)
      if inventory_item.nil?
        errors.add(:storage_location,
                   "#{line_item.item.name} is not available " \
                   "at this storage location")
      end
    end
  end
end
