def random_keys(sample_size)
  CanonicalItem.all.pluck(:partner_key).sample(sample_size).uniq.map(&:to_sym)
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
