FactoryBot.define do
  factory :distribution_created_event, class: DistributionCreated do
    organization
    event_time { Time.zone.now }
  end

  factory :donation_created_event, class: DonationCreated do
    organization
    event_time { Time.zone.now }
  end
end

