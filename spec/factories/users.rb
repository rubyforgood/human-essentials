# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :integer          default(0)
#  invited_by_type        :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :bigint
#  partner_id             :bigint
#

FactoryBot.define do
  factory :user do
    name { "Diaper McDiaperface" }
    sequence(:email, 100) { |n| "person#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    organization { Organization.try(:first) || create(:organization) }

    factory :organization_admin do
      name { "Very Organized Admin" }
      organization_admin { true }
    end

    factory :super_admin do
      name { "Administrative User" }
      super_admin { true }
    end

    factory :super_admin_no_org do
      name { "Administrative User No Org" }
      super_admin { true }
      organization_id { nil }
    end

    trait :deactivated do
      discarded_at { Time.zone.now }
    end
  end
end
