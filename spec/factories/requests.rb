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

def random_keys(sample_size)
  Item.all.pluck(:id).sample(sample_size)
end

FactoryBot.define do
  factory :request do
    partner { Partner.try(:first) || create(:partner) }
    organization { Organization.try(:first) || create(:organization) }
    request_items { random_keys(3).map {|k| { "item_id" => k, "quantity" => rand(3..10) } } }
    status { "Active" }
    comments { "Urgent" }
  end
end
