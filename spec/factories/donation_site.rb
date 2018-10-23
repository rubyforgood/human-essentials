FactoryBot.define do
  factory :donation_site do
    organization { Organization.try(:first) || create(:organization) }
    name { "Smithsonian Conservation Center" }
    address { "1111 Panda ave. Front Royal, VA 12345" }
  end
end
