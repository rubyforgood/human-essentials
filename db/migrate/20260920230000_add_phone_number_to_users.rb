class AddPhoneNumberToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_number, :string
  end
end
