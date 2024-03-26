class AddRoleService
  # @param user_id [Integer]
  # @param resource_id [Integer]
  # @param resource_type [String]
  def self.call(user_id:, resource_type:, resource_id: nil)
    user = User.find(user_id)
    if resource_type.to_sym == Role::SUPER_ADMIN
      add_super_admin(user)
      return
    end
    klass = Role::TITLE_TO_RESOURCE[resource_type.to_sym]
    resource = klass.find(resource_id)
    if user.has_role?(resource_type, resource)
      raise "User #{user.display_name} already has role for #{resource.name}"
    end
    user.add_role(resource_type, resource)
    if resource_type.to_sym == Role::ORG_ADMIN
      user.add_role(:org_user, resource)
    end
  end

  # @param user [User]
  def self.add_super_admin(user)
    if user.has_role?(Role::SUPER_ADMIN)
      raise "User #{user.display_name} already has super admin role!"
    end
    user.add_role(Role::SUPER_ADMIN)
  end
end
