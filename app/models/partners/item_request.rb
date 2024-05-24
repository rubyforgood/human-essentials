# == Schema Information
#
# Table name: item_requests
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  partner_key            :string
#  quantity               :string
#  request_unit           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  item_id                :integer
#  old_partner_request_id :integer
#  partner_request_id     :bigint
#
module Partners
  class ItemRequest < Base
    has_paper_trail
    belongs_to :request, class_name: '::Request', foreign_key: :partner_request_id, inverse_of: :item_requests
    belongs_to :item
    has_many :child_item_requests, dependent: :destroy
    has_many :children, through: :child_item_requests

    validates :quantity, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :name, presence: true
    validates :partner_key, presence: true
    validate :request_unit_is_supported

    def request_unit_is_supported
      return if request_unit.blank?

      names = item.request_units.map(&:name)
      unless names.include?(request_unit)
        errors.add(:request_unit, "is not supported")
      end
    end
  end
end
