# == Schema Information
#
# Table name: users_roles
#
#  id      :bigint           not null, primary key
#  role_id :bigint
#  user_id :bigint
#
class UsersRole < ApplicationRecord
  has_paper_trail
  belongs_to :user
  belongs_to :role
  has_one :last_user, class_name: "User", foreign_key: :last_role_id, inverse_of: :last_role, dependent: :nullify

  accepts_nested_attributes_for :user

  validates :role, uniqueness: {scope: :user}

  # @param user [User]
  # @return [Role,nil]
  def self.current_role_for(user)
    return nil if user.nil?
    return user.last_role if user.last_role

    role_order = [Role::SUPER_ADMIN, Role::ORG_ADMIN, Role::ORG_USER, Role::PARTNER]
    role_order.each do |role|
      found_role = user&.roles&.find { |r| r.name.to_sym == role }
      return found_role if found_role
    end

    nil
  end

  # @param user [User]
  # @param role [Role]
  def self.set_last_role_for(user, role)
    users_role = UsersRole.find_by(user: user, role: role)
    return if users_role.nil?

    user.update(last_role_id: users_role.id)
  end
end
