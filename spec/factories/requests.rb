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

def random_request_items
  keys = Item.active.pluck(:id).sample(3)
  keys.map { |k| { "item_id" => k, "quantity" => rand(3..10) } }
end

FactoryBot.define do
  factory :request do
    partner { Partner.try(:first) || create(:partner) }
    organization { Organization.try(:first) || create(:organization, :with_items) }
    request_items { random_request_items }
    comments { "Urgent" }
    partner_user { ::User.partner_users.first || create(:partners_user) }
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

  trait :with_varied_quantities do
    request_items {
      # get 10 unique item ids
      keys = Item.active.pluck(:id).sample(10)

      # This *could* pass in error -- if the plucking order happens to match the end order.

      item_quantities = [50, 150, 75, 125, 200, 3, 15, 88, 46, 22]
      keys.map.with_index { |k, i| { "item_id" => k, "quantity" => item_quantities[i]} }
    }
  end
end
