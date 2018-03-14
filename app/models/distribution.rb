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

  validates :storage_location, :partner, :organization, presence: true
  validate :line_item_items_exist_in_inventory

  include IssuedAt

  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }
  scope :during, ->(range) { where(distributions: { issued_at: range }) }

  delegate :name, to: :partner, prefix: true

  def distributed_at
    issued_at.strftime("%B %-d %Y")
  end
end
