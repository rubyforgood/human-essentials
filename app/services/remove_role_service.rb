class RemoveRoleService
  # @param user_id [Integer]
  # @param role_id [Integer]
  # @param resource_type [String]
  # @param resource_id [Integer]
  def self.call(user_id:, role_id: nil, resource_type: nil, resource_id: nil)
    if role_id.nil? && resource_id.nil?
      raise "Must provide either a role ID or resource ID!"
    end
    if role_id.nil?
      role_id = Role.find_by(name: resource_type, resource_id: resource_id).id
    end
    user_role = UsersRole.find_by(user_id: user_id, role_id: role_id)
    unless user_role
      user = User.find(user_id)
      role = Role.find(role_id)
      raise "User #{user.display_name} does not have role for #{role.resource.name}!"
    end

    user_role.destroy

    if user_role.role.name.to_sym == Role::ORG_USER # they can't be an admin if they're not a user
      admin_role = Role.find_by(resource_id: user_role.role.resource_id, name: Role::ORG_ADMIN)
      if admin_role
        UsersRole.find_by(user_id: user_id, role_id: admin_role.id)&.destroy
      end
    end
  end
end
