# == Schema Information
#
# Table name: requests
#
#  id              :bigint           not null, primary key
#  comments        :text
#  discard_reason  :text
#  discarded_at    :datetime
#  request_items   :jsonb
#  status          :integer          default("pending")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  distribution_id :integer
#  organization_id :bigint
#  partner_id      :bigint
#

class Request < ApplicationRecord
  include Discard::Model
  include Exportable

  class MismatchedItemIdsError < StandardError; end

  belongs_to :partner
  belongs_to :organization
  belongs_to :distribution, optional: true

  enum status: { pending: 0, started: 1, fulfilled: 2 }, _prefix: true

  validates :distribution_id, uniqueness: true, allow_nil: true
  before_save :sanitize_items_data

  include Filterable
  # add request item scope to allow filtering distributions by request item
  scope :by_request_item_id, ->(item_id) { where("request_items @> :with_item_id ", with_item_id: [{ item_id: item_id.to_i }].to_json) }
  # partner scope to allow filtering by partner
  scope :by_partner, ->(partner_id) { where(partner_id: partner_id) }
  # status scope to allow filtering by status
  scope :by_status, ->(status) { where(status: status) }
  scope :during, ->(range) { where(created_at: range) }
  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .includes(:partner)
      .order(created_at: :desc)
  }

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

  def self.generate_csv(requests)
    rows = Exports::ExportRequestService.new(requests).call
    CSV.generate(headers: true) do |csv|
      rows.each { |row| csv << row }
    end
  end

  def total_items
    request_items.sum { |item| item["quantity"] }
  end

  private

  def sanitize_items_data
    return unless request_items && request_items_changed?

    self.request_items = request_items.map do |item|
      item.merge("item_id" => item["item_id"]&.to_i, "quantity" => item["quantity"]&.to_i)
    end
  end
end
