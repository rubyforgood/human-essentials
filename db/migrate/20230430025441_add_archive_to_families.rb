class AddArchiveToFamilies < ActiveRecord::Migration[7.0]
  def up
    add_column :families, :archived, :boolean
    change_column_default :families, :archived, false
  end

  def down
    remove_column :families, :archived
  end
end

class BackfillAddArchiveToFamilies < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    Family.unscoped.in_batches do |relation|
      relation.update_all archived: false
      sleep(0.01)
    end
  end
end
