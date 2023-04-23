class FixBadUserRoles < ActiveRecord::Migration[7.0]
  def change
    bad_roles = Role.all.select { |r| r.resource_type && r.resource.nil? }

    bad_roles.each do |role|
      UsersRole.where(role_id: role.id).destroy_all
      role.destroy
    end
  end
end
