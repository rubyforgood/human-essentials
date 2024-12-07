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
    contact_name { "Don Draper" }
    business_name { "Awesome Business" }
    address { "123 Front Street, Atlanta, Georgia, 54321" }
    sequence(:email) { |n| "don#{n}@scdp.com" }
    phone { "212-555-1111" }
    comment { "A bit of a lush and philanderer." }
  end
end
