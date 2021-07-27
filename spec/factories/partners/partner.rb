FactoryBot.define do
  factory :partners_partner, class: Partners::Partner do
    diaper_bank_id { Organization.try(:first).id || create(:organization).id }
  end
end
