module CurrentRole
  def current_role
    caching_current_role do
      deprecating_session_role do
        _current_role
      end
    end
  end

  def set_current_role(role)
    caching_current_role { role }
  end

  private

  def _current_role
    UsersRole.current_role_for current_user
  end

  def caching_current_role(&current_role_finder)
    @previous_role ||= nil
    role = current_role_finder.call
    return role if role == @previous_role

    activate_role role
    @previous_role = role
  end

  def activate_role(role)
    return unless role && current_user

    UsersRole.activate! role: role, user: current_user
    current_user.reload_current_role
  end

  def deprecating_session_role(&current_role_finder)
    return current_role_finder.call unless session[:current_role]

    Rails.logger.info "Current role loaded from session"
    role_id = session.delete :current_role
    role = current_user&.roles&.find_by id: role_id
    role || current_role_finder.call
  end
end
