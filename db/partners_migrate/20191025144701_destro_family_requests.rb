class DestroFamilyRequests < ActiveRecord::Migration[5.2]
  def up
    execute "DROP TABLE #{:family_requests} CASCADE"
    drop_table :family_request_children
  end

  def down
    raise 'Migration is not reversible.'
  end
end
