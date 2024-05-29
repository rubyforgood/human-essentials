class BackfillAddDeactivatedToUsersRole < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    UsersRole.unscoped.joins(:user).where("users.discarded_at": nil).in_batches do |relation|
      relation.update_all(deactivated: false)
      sleep(0.01)
    end

    UsersRole.unscoped.joins(:user).where.not("users.discarded_at": nil).in_batches do |relation|
      relation.update_all(deactivated: true)
      sleep(0.01)
    end
  end
end

