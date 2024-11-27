class ReactivateUsersAndRemoveOrgUserRoles < ActiveRecord::Migration[7.1]
  def up
    users = User.unscoped.where.not(discarded_at: nil)
    users.each do |user|
      user.transaction do
        user.update!(discarded_at: nil)
        user.roles.delete_all
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
