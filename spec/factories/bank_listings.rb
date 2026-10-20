FactoryBot.define do
  factory :bank_listing do
    sequence(:name) { |n| "Pawnee Diaper Bank #{n}" }
    name_key { CensusLocation.key_for(name) }
    city { "Dayton" }
    state { "OH" }
    website { "www.pawneediapers.example" }
    diapers { true }
    latitude { 39.784743 }
    longitude { -84.199632 }
  end
end
