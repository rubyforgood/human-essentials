# == Schema Information
#
# Table name: organizations
#
#  id              :integer          not null, primary key
#  name            :string
#  short_name      :string
#  email           :string
#  url             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  intake_location :integer
#  street          :string
#  city            :string
#  state           :string
#  zipcode         :string
#  latitude        :float
#  longitude       :float
#

FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Diaper Bank #{n}" } # 037000863427
    sequence(:short_name) { |n| "db_#{n}" } # 037000863427
    sequence(:email) { |n| "email#{n}@example.com" } # 037000863427
    sequence(:url) { |n| "https://organization#{n}.org" } # 037000863427
    street { "1500 Remount Road" }
    city { 'Front Royal' }
    state { 'VA' }
    zipcode { '22630' }

    logo { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/logo.jpg"), "image/jpeg") }

    after(:create) do |instance, _evaluator|
      Organization.seed_items(instance)
    end
  end
end
