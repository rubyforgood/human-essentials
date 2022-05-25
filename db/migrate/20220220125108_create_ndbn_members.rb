class CreateNDBNMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :ndbn_members, primary_key: :ndbn_member_id do |t|
      t.string :account_name, null: false

      t.timestamps
    end
  end
end
