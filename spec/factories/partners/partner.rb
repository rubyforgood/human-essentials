FactoryBot.define do
  factory :partners_partner, class: Partners::Partner do
    essentials_bank_id { Organization.try(:first).id || create(:organization).id }
  end
end
