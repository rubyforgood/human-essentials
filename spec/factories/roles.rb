# == Schema Information
#
# Table name: roles
#
#  id              :bigint           not null, primary key
#  name            :string
#  resource_type   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  old_resource_id :bigint
#  resource_id     :bigint
#
FactoryBot.define do
  factory :role do
  end
end
