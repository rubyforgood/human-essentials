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
  BaseItem.all.pluck(:partner_key).sample(sample_size).uniq.map(&:to_sym)
end

FactoryBot.define do
  factory :request do
    partner { Partner.try(:first) || create(:partner) }
    organization { Organization.try(:first) || create(:organization) }
    request_items { random_keys(3).collect { |k| [k, rand(3..10)] }.to_h }
    status { "Active" }
    comments { "Urgent" }
  end
end
