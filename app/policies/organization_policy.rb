class OrganizationPolicy < ApplicationPolicy
  def allowed?
    return true if user.has_role?(:super_admin)

    (user.has_role?(:bank) || user.has_role?(:org_admin)) && user.organization_id == organization.id
  end

  def allowed_admin?
    return true if user.has_role?(:super_admin)

    user.has_role?(:org_admin) && user.organization_id == organization.id
  end

end
