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

def random_request_items
  keys = Item.active.pluck(:id).sample(3)
  keys.map { |k| { "item_id" => k, "quantity" => rand(3..10) } }
end

FactoryBot.define do
  factory :request do
    partner { Partner.try(:first) || create(:partner) }
    organization { Organization.try(:first) || create(:organization) }
    request_items { random_request_items }
    comments { "Urgent" }
  end

  trait :started do
    status { 'started' }
  end

  trait :fulfilled do
    status { 'fulfilled' }
  end

  trait :pending do
    status { 'pending' }
  end
end
