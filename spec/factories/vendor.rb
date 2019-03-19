# == Schema Information
#
# Table name: vendor
#
#  id              :bigint(8)        not null, primary key
#  contact_name    :string
#  email           :string
#  phone           :string
#  comment         :string
#  organization_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  address         :string
#  business_name   :string
#  latitude        :float
#  longitude       :float
#

FactoryBot.define do
  factory :vendor do
    organization { Organization.try(:first) || create(:organization) }
    contact_name { "Don Draper" }
    business_name { "Awesome Business" }
    sequence(:email) { |n| "don#{n}@scdp.com" }
    phone { "212-555-1111" }
    comment { "A bit of a lush and philanderer." }
  end
end
