FactoryBot.define do
  factory :partner_profile, class: Partners::Profile do
    partner { Partner.first || create(:partner) }
    essentials_bank_id { Organization.try(:first).id || create(:organization).id }
  end
end
