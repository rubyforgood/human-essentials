# == Schema Information
#
# Table name: distributions
#
#  id                  :bigint(8)        not null, primary key
#  comment             :text
#  created_at          :datetime
#  updated_at          :datetime
#  storage_location_id :integer
#  partner_id          :integer
#  organization_id     :integer
#  issued_at           :datetime
#  agency_rep          :string
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

  validates :issued_at, :storage_location, :partner, :organization, presence: true
  validate :line_item_items_exist_in_inventory

  include IssuedAt

  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }
  scope :during, ->(range) { where(distributions: { issued_at: range }) }
  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .includes(:partner, :storage_location, :line_items)
  }

  delegate :name, to: :partner, prefix: true

  def distributed_at
    issued_at.strftime("%B %-d %Y")
  end

  def combine_duplicates
    Rails.logger.info "Combining!"
    line_items.combine!
  end

  def copy_line_items(donation_id)
    line_items = LineItem.where(itemizable_id: donation_id, itemizable_type: "Donation")
    line_items.each do |line_item|
      self.line_items.new(line_item.attributes)
    end
  end

  def copy_from_donation(donation_id, storage_location_id)
    copy_line_items(donation_id) if donation_id
    self.storage_location = StorageLocation.find(storage_location_id) if storage_location_id
  end

  def self.csv_export_headers
    ["Partner", "Date of Distribution", "Source Inventory", "Total items"]
  end

  def csv_export_attributes
    [
      partner.name,
      issued_at.strftime("%F"),
      storage_location.name,
      line_items.total
    ]
  end
end
