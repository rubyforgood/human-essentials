class MovePartnerForRoles < ActiveRecord::Migration[7.0]
  Partner # load this so Rolify doesn't get confused that we don't have the resource type

  def up
    unless column_exists?(:roles, :old_resource_id)
      add_column :roles, :old_resource_id, :bigint
    end

    update_sql = <<-SQL
      UPDATE roles 
      SET old_resource_id=resource_id 
      WHERE old_resource_id IS NULL AND resource_type='Partners::Partner'
SQL
    Role.connection.execute(update_sql)

    Role.where(resource_type: 'Partners::Partner').find_each do |record|
      record.update!(
        resource_type: 'Partner',
        resource_id: Partners::Profile.find_by(id: record.old_resource_id).partner_id
      )
    end
  end

  def down
    if column_exists?(:roles, :old_resource_id)
      remove_column :roles, :old_resource_id
    end
  end

end
