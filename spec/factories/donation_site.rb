FactoryBot.define do
  factory :donation_site do
    organization { Organization.try(:first) || create(:organization) }
    name { "Smithsonian Conservation Center" }
    address { "1500 Remount Road, Front Royal, VA 22630" }
  end
end
