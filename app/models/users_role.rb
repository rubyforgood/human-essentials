# == Schema Information
#
# Table name: users_roles
#
#  id      :bigint           not null, primary key
#  role_id :bigint
#  user_id :bigint
#
class UsersRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  accepts_nested_attributes_for :user

  # @param user [User]
  # @return [Role,nil]
  def self.current_role_for(user)
    role_order = [Role::SUPER_ADMIN, Role::ORG_ADMIN, Role::ORG_USER, Role::PARTNER]
    role_order.each do |role|
      found_role = user&.roles&.find { |r| r.name.to_sym == role }
      return found_role if found_role
    end

    nil
  end
end
