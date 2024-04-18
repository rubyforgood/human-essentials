class ChangeUserNameDefaultAndAllowNull < ActiveRecord::Migration[7.0]
  def up
    # Change the default value of `name` to `nil` and allow `null` values
    change_column :users, :name, :string, default: nil, null: true

    # Optional: You can also add a line here to update all existing records
    # with 'Name Not Provided' to `nil`
    User.where(name: 'Name Not Provided').update_all(name: nil)
  end

  def down
    # Revert the `name` column to not allow null and set the default value back
    change_column :users, :name, :string, default: 'Name Not Provided', null: false
  end
end
