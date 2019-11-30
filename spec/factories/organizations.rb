# == Schema Information
#
# Table name: organizations
#
#  id              :bigint           not null, primary key
#  city            :string
#  deadline_day    :integer
#  email           :string
#  intake_location :integer
#  invitation_text :text
#  latitude        :float
#  longitude       :float
#  name            :string
#  reminder_day    :integer
#  short_name      :string
#  state           :string
#  street          :string
#  url             :string
#  zipcode         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :organization do
    transient do
      skip_items { false }
    end

    sequence(:name) { |n| "Diaper Bank #{n}" } # 037000863427
    sequence(:short_name) { |n| "db_#{n}" } # 037000863427
    sequence(:email) { |n| "email#{n}@example.com" } # 037000863427
    sequence(:url) { |n| "https://organization#{n}.org" } # 037000863427
    street { "1500 Remount Road" }
    city { 'Front Royal' }
    state { 'VA' }
    zipcode { '22630' }
    reminder_day { 10 }
    deadline_day { 20 }

    logo { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/logo.jpg"), "image/jpeg") }

    after(:create) do |instance, evaluator|
      Organization.seed_items(instance) unless evaluator.skip_items
    end
  end
end
