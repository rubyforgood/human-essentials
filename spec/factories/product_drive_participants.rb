# == Schema Information
#
# Table name: product_drive_participants
#
#  id              :integer          not null, primary key
#  address         :string
#  business_name   :string
#  comment         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

FactoryBot.define do
  factory :product_drive_participant do
    organization { Organization.try(:first) || create(:organization) }
    contact_name { "Dont test this" }
    sequence(:email) { |n| "dont#{n}@testthis.com" }

    trait :no_contact_name_or_email do
      contact_name { nil }
      email { nil }
    end
  end
end
