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
#  partner_user_id :integer
#

class Request < ApplicationRecord
  include Discard::Model
  include Exportable

  belongs_to :partner
  belongs_to :partner_user, class_name: "Partners::User", optional: true
  belongs_to :organization
  belongs_to :distribution, optional: true

  enum status: { pending: 0, started: 1, fulfilled: 2, discarded: 3 }, _prefix: true

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
