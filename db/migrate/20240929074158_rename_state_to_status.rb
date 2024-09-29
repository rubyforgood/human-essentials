class RenameStateToStatus < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_column :distributions, :status, :integer


    safety_assured do
      # backfill data from state to status
      execute <<-SQL
        UPDATE distributions SET status = state;
      SQL

      # remove state
      remove_column :distributions, :state

      change_column_default :distributions, :status, 5
      change_column_null :distributions, :status, false
    end
  end

  def down
    add_column :distributions, :state, :integer, null: false

    safety_assured do
      # backfill data from status to state
      execute <<-SQL
        UPDATE distributions SET state = status;
      SQL

      # remove status column
      remove_column :distributions, :status

      change_column_default :distributions, :state, 5
      change_column_null :distributions, :state, false
    end
  end
end
