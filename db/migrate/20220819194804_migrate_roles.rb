class MigrateRoles < ActiveRecord::Migration[7.0]
  def change
    User.find_each do |user|
      if user.organization_id.present?
        user.add_role(:org_user, Organization.find(user.organization_id))
      end
      if user.partner_id.present?
        user.add_role(:partner, Partners::Partner.find(user.partner_id))
      end
      if user.super_admin?
        user.add_role(:super_admin)
      elsif user.organization_admin?
        user.add_role(:org_admin, Organization.find(user.organization_id))
    end
  end
end
