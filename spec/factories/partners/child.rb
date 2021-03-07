FactoryBot.define do
  factory :partners_child, class: Partners::Child do
    association :family, factory: :partners_family

    active               { true }
    archived             { false }
    comments             { 'Comments ' }
    date_of_birth        { Time.zone.today - 5.years }
    first_name           { Faker::Name.first_name }
    last_name            { Faker::Name.last_name }
    gender               { Faker::Gender.binary_type }
    item_needed_diaperid { rand(1..10) }
  end
end
