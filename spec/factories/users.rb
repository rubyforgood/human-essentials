# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :integer
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_type        :string
#  invited_by_id          :integer
#  invitations_count      :integer          default(0)
#  organization_admin     :boolean
#  name                   :string           default("CHANGEME"), not null
#  super_admin            :boolean          default(FALSE)
#  last_request_at        :datetime
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
  end
end
