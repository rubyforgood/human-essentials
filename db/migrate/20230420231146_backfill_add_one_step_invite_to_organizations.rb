class BackfillAddOneStepInviteToOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    Organization.unscoped.in_batches do |relation|
      relation.update_all enable_one_step_invite: false
      sleep(0.01)
    end
  end
end
