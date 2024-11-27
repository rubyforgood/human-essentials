# == Schema Information
#
# Table name: children
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  archived             :boolean
#  child_lives_with     :jsonb
#  comments             :text
#  date_of_birth        :date
#  first_name           :string
#  gender               :string
#  health_insurance     :jsonb
#  item_needed_diaperid :integer
#  last_name            :string
#  race                 :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  agency_child_id      :string
#  family_id            :bigint
#
FactoryBot.define do
  factory :partners_child, class: Partners::Child do
    association :family, factory: :partners_family

    active { true }
    archived { false }
    comments { "Comments " }
    date_of_birth { Time.zone.today - 5.years }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    gender { Faker::Gender.binary_type }
    requested_item_ids { [create(:item, organization: family.partner.organization).id] }
  end
end
