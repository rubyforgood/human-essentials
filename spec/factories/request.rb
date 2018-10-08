FactoryBot.define do
  factory :request do
    partner { Partner.try(:first) || create(:partner) }
    organization { Organization.try(:first) || create(:organization) }
    request_items { { k_size5: 3, k_size6: 2 } }
    status "Active"
    comments "Urgent"
  end
end
