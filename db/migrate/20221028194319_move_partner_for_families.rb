class MovePartnerForFamilies < ActiveRecord::Migration[7.0]
  KLASS = Partners::Family

  def up
    table_name = KLASS.table_name

    unless column_exists?(table_name, :old_partner_id)
      add_column table_name, :old_partner_id, :bigint
    end
    if foreign_key_exists?(table_name, :partner_profiles, column: :partner_id)
      remove_foreign_key(table_name, :partner_profiles, column: :partner_id)
    end

    update_sql = "UPDATE #{table_name} SET old_partner_id=partner_id WHERE old_partner_id IS NULL"
    KLASS.connection.execute(update_sql)

    KLASS.find_each do |record|
      record.update!(partner_id: Partners::Profile.find_by(id: record.old_partner_id).partner_id)
    end

    unless foreign_key_exists?(table_name, :partners)
      safety_assured { add_foreign_key(table_name, :partners) }
    end

  end

  def down
    table_name = KLASS.table_name

    if column_exists?(table_name, :old_partner_id)
      remove_column table_name, :old_partner_id
    end
    unless foreign_key_exists?(table_name, :partner_profiles, column: :partner_id)
      add_foreign_key(table_name, :partner_profiles, column: :partner_id)
    end
  end

end
