# == Schema Information
#
# Table name: users_roles
#
#  id      :bigint           not null, primary key
#  role_id :bigint
#  user_id :bigint
#
FactoryBot.define do
  factory :users_role do
    user
    role
  end
end
