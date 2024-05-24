module UserInviteService
  # @param name [String]
  # @param email [String]
  # @param roles [Array<Symbol>]
  # @param resource [ApplicationRecord]
  # @param force [Boolean]
  # @return [User]
  def self.invite(email:, resource:, name: nil, roles: [], force: false)
    raise "Resource not found!" if resource.nil?

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
