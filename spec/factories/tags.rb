# == Schema Information
#
# Table name: tags
#
#  id              :bigint           not null, primary key
#  name            :string(256)      not null
#  type            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#
FactoryBot.define do
  factory :tag do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:name) { |n| "Tag #{n}" }
    type { "ProductDrive" }
  end
end
