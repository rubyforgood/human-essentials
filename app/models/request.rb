# == Schema Information
#
# Table name: requests
#
#  id              :bigint(8)        not null, primary key
#  partner_id      :bigint(8)
#  organization_id :bigint(8)
#  status          :string           default("Active")
#  request_items   :jsonb
#  comments        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Request < ApplicationRecord
  belongs_to :partner
  belongs_to :organization
  belongs_to :distribution, optional: true

  scope :active, -> { where(status: "Active") }

  STATUSES = %w[Active Fulfilled].freeze

  def items_hash
    @items_hash ||= request_items.collect do |key, _quantity|
      [key, CanonicalItem.find_by(partner_key: key).items.first]
    end.to_h
  end
end
