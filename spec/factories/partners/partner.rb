FactoryBot.define do
  factory :partners_partner, class: Partners::Partner do
    diaper_bank_id { Organization.try(:first).id || create(:organization).id }

    after(:build) do |partners_partner, _option|
      org_partner = FactoryBot.create(:partner)
      partners_partner.diaper_partner_id = org_partner.id
    end
  end
end
