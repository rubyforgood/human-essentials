class SuperAdminPolicy < ApplicationPolicy
  def allowed?
    @user.has_role?(:super_admin)
  end
end
