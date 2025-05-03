# == Schema Information
#
# Table name: donation_sites
#
#  id              :integer          not null, primary key
#  active          :boolean          default(TRUE)
#  address         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  name            :string
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#
FactoryBot.define do
  factory :donation_site do
    organization { Organization.try(:first) || create(:organization) }
    name { Faker::Company.name }
    address { "1500 Remount Road, Front Royal, VA 22630" }
    active { true }
    contact_name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
  end
end
