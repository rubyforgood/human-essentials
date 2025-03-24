module UserInviteService
  # @param name [String]
  # @param email [String]
  # @param roles [Array<Symbol>]
  # @param resource [ApplicationRecord]
  # @param force [Boolean]
  # @return [User]
  def self.invite(email:, resource:, name: nil, roles: [], force: false)
    # Because only one resource can be passed, currently the only case where
    # multiple roles being based makes sense is ORG_USER and ORG_ADMIN.

    # Resource can be nil when the only role(s) being added don't require a resource
    raise "Resource not found!" if resource.nil? && roles.map(&:to_s).any? { |role| !Role::ROLES_WITHOUT_RESOURCE.map(&:to_s).include?( role ) }

    # A user with the ORG_ADMIN role should also always have the ORG_USER role.
    # The logic is placed here instead of relying on the AddRoleService, as that
    # currently only accepts users by id, and new user will not have an id
    # until after they are invited.
    if roles.map(&:to_s).include?( Role::ORG_ADMIN.to_s )
      roles.append(Role::ORG_USER.to_s)
    end

    user = User.find_by(email: email)

    # return if user already has all the roles we're trying to add
    if !force && user && roles.all? { |role| user.has_role?(role, resource) }
      raise "User already has the requested role!"
    end

    if user
      add_roles(user, resource: resource, roles: roles)
      if force
        user.invite!
      else
        UserMailer.role_added(user, resource, roles).deliver_later
      end
      return user
    end

    User.invite!(email: email) do |user1|
      name = nil if name.blank?
      user1.name = name.presence || nil
      add_roles(user1, resource: resource, roles: roles)
      user1.skip_invitation = user1.errors[:email].any?
    end
  end

  def self.add_roles(user, resource:, roles: [])
    roles.each do |role|
      user.add_role(role, resource)
    end
  end
end
