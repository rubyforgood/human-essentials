class ReactivateUsersAndRemoveOrgUserRoles < ActiveRecord::Migration[7.1]
  def up
    users = User.unscoped.joins(:roles).where.not(discarded_at: nil).where("roles.name": "org_user")
    users.each do |user|
      user.transaction do
        user.update!(discarded_at: nil)
        user.roles.where(name: "org_user").delete_all
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
