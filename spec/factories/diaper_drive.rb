FactoryBot.define do
  factory :diaper_drive do
    name { "Test Drive" }
    start_date { Time.current }
    end_date { Time.current }
    virtual { [true, false].sample }
    organization { Organization.try(:first) || create(:organization) }
  end
end
