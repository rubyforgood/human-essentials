# == Schema Information
#
# Table name: requests
#
#  id              :bigint           not null, primary key
#  comments        :text
#  discard_reason  :text
#  discarded_at    :datetime
#  request_items   :jsonb
#  request_type    :string
#  status          :integer          default("pending")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  distribution_id :integer
#  organization_id :bigint
#  partner_id      :bigint
#  partner_user_id :integer
#

class Request < ApplicationRecord
  has_paper_trail
  include Discard::Model
  include Exportable

  belongs_to :partner
  belongs_to :partner_user, class_name: "::User", optional: true
  belongs_to :organization
  belongs_to :distribution, optional: true

  has_many :item_requests, class_name: "Partners::ItemRequest", foreign_key: :partner_request_id, dependent: :destroy, inverse_of: :request
  accepts_nested_attributes_for :item_requests, allow_destroy: true, reject_if: proc { |attributes| attributes["quantity"].blank? }
  has_many :child_item_requests, through: :item_requests

  enum :status, { pending: 0, started: 1, fulfilled: 2, cancelled: 3 }, prefix: true
  enum :request_type, %w[quantity individual child].map { |v| [v, v] }.to_h

  validates :distribution_id, uniqueness: true, allow_nil: true
  validate :item_requests_uniqueness_by_item_id
  validate :not_completely_empty
  validate :cannot_change_status_once_fulfilled,
    :cannot_change_status_once_cancelled,
    on: :update

  after_validation :sanitize_items_data

  include Filterable

  # add request item scope to allow filtering distributions by request item
  scope :by_request_item_id, ->(item_id) { where("request_items @> :with_item_id ", with_item_id: [{ item_id: item_id.to_i }].to_json) }
  # partner scope to allow filtering by partner
  scope :by_partner, ->(partner_id) { where(partner_id: partner_id) }
  # status scope to allow filtering by status
  scope :by_status, ->(status) { where(status: status) }
  scope :by_request_type, ->(request_type) { where(request_type: request_type) }
  scope :during, ->(range) { where(created_at: range) }

  def total_items
    request_items.sum { |item| item["quantity"] }
  end

  def requester
    # Despite the field being called "partner_user_id", it can refer to both a partner user or an organization admin
    partner_user_id ? partner_user : partner
  end

  def request_type_label
    request_type&.first&.capitalize
  end

  private

  def item_requests_uniqueness_by_item_id
    item_ids = item_requests.map(&:item_id)
    if item_ids.uniq.length != item_ids.length
      errors.add(:item_requests, "should have unique item_ids")
    end
  end

  def sanitize_items_data
    return unless request_items && request_items_changed?

    self.request_items = request_items.map do |item|
      item.merge("item_id" => item["item_id"]&.to_i, "quantity" => item["quantity"]&.to_i)
    end
  end

  # **This message is shown to partners verbatim.** `partners/requests/_error` prints every base
  # error as a bullet, so it has to be a sentence rather than the note-to-self it was
  # ("completely empty request"). It describes the *state* and not the remedy, because the
  # remedy differs by form and the callout's guidance line above the list already gives it:
  # "Choose at least one child" on the family form, "every line needs an item selected" on the
  # other two.
  def not_completely_empty
    if comments.blank? && item_requests.blank?
      errors.add(:base, "The request is empty: it has no items and no comment.")
    end
  end

  def cannot_change_status_once_fulfilled
    if status_changed? && status_was == "fulfilled"
      errors.add(:status, "cannot be changed once fulfilled")
    end
  end

  def cannot_change_status_once_cancelled
    if status_changed? && status_was == "cancelled"
      errors.add(:status, "cannot be changed once cancelled")
    end
  end
end
