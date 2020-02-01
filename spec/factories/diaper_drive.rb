FactoryBot.define do
  factory :diaper_drive do
    name { "Test Drive" }
    start_date { Time.current }
    organization { Organization.try(:first) || create(:organization) }
  end
end