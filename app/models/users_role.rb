# == Schema Information
#
# Table name: users_roles
#
#  role_id :bigint
#  user_id :bigint
#
class UsersRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  accepts_nested_attributes_for :user
end
