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
#  distribution_id :integer
#

class Request < ApplicationRecord
  belongs_to :partner
  belongs_to :organization
  belongs_to :distribution, optional: true
  has_many :item_requests, dependent: :destroy

  enum status: { pending: 0, started: 1, fulfilled: 2 }, _prefix: true

  def family_request_reply
    {
      "organization_id": organization_id,
      "partner_id": partner_id,
      "requested_items": item_requests.map do |ir|
        {
          "item_id": ir.item_id,
          "count": ir.quantity,
          "item_name": ir.item.name
        }
      end
    }
  end

  def self.parse_family_request(family_request)
    request = Request.new(organization_id: family_request['organization_id'], partner_id: family_request['partner_id'])
    request.item_requests = []

    family_request['requested_items'].each do |item|
      item_request = ItemRequest.new
      item_request.item = Item.find(item['item_id'])
      item_request.quantity = item_request.item.default_quantity * item['person_count']
      request.item_requests << item_request
    end

    request
  end
end
