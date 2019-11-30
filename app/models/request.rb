# == Schema Information
#
# Table name: requests
#
#  id              :bigint           not null, primary key
#  comments        :text
#  request_items   :jsonb
#  status          :integer          default("pending")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  distribution_id :integer
#  organization_id :bigint
#  partner_id      :bigint
#

class Request < ApplicationRecord
  class MismatchedItemIdsError < StandardError; end
  belongs_to :partner
  belongs_to :organization
  belongs_to :distribution, optional: true

  enum status: { pending: 0, started: 1, fulfilled: 2 }, _prefix: true

  scope :during, ->(range) { where(created_at: range) }

  def family_request_reply
    {
      "organization_id": organization_id,
      "partner_id": partner_id,
      "requested_items": request_items.map do |item|
        {
          "item_id": item['item_id'],
          "count": item['quantity'],
          "item_name": item['name']
        }
      end
    }
  end

  # TODO: Add permission checks for request creation and item lookup
  def self.parse_family_request(family_request)
    request = Request.new(organization_id: family_request['organization_id'], partner_id: family_request['partner_id'])
    requested_items = family_request['requested_items'].sort_by { |item| item['item_id'] }

    request.request_items =
      Item.where(id: requested_items.map { |item| item['item_id'] })
          .order(:id).each.with_index.with_object([]) do |(item, index), request_items|
        unless requested_items[index]['item_id'] == item.id
          raise MismatchedItemIdsError,
                'Item ids should match existing Diaper Base item ids.'
        end
        request_items << {
          item_id: item.id,
          quantity: item.default_quantity * requested_items[index]['person_count'],
          name: item.name
        }
      end
    request
  end
end
