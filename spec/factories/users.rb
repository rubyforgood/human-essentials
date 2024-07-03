# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  discarded_at           :datetime
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :integer          default(0)
#  invited_by_type        :string
#  last_request_at        :datetime
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string
#  organization_admin     :boolean
#  provider               :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  super_admin            :boolean          default(FALSE)
#  uid                    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :integer
#  last_role_id           :bigint
#  organization_id        :integer
#  partner_id             :bigint
#

FactoryBot.define do
  factory :user do
    name { "Diaper McDiaperface" }
    sequence(:email, 100) { |n| "person#{n}@example.com" }
    password { "password!" }
    password_confirmation { "password!" }
    transient do
      organization { Organization.try(:first) || create(:organization) }
    end

    after(:create) do |user, evaluator|
      if evaluator.organization
        user.add_role(Role::ORG_USER, evaluator.organization)
      end
    end

    factory :organization_admin do
      name { "Very Organized Admin" }
      after(:create) do |user, evaluator|
        if evaluator.organization
          AddRoleService.call(user_id: user.id,
            resource_id: evaluator.organization.id,
            resource_type: Role::ORG_ADMIN)
        end
      end
    end

    factory :super_admin do
      name { "Administrative User" }
      after(:create) do |user|
        user.add_role(Role::SUPER_ADMIN)
      end
    end

    factory :super_admin_no_org do
      name { "Administrative User No Org" }
      after(:create) do |user, evaluator|
        user.add_role(Role::SUPER_ADMIN)
        user.remove_role(Role::ORG_USER, evaluator.organization)
      end
    end

    trait :no_roles do
      organization { nil }
    end

    trait :deactivated do
      discarded_at { Time.zone.now }
    end
  end
end
