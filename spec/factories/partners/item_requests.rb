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
FactoryBot.define do
  factory :item_request, class: Partners::ItemRequest do
    item
    request { build(:request, organization: item.organization) }
    quantity { 5 }
    sequence(:name) { |n| "Item Request #{n}" }
    sequence(:partner_key) { |n| "partner_key#{n}" }
  end
end
