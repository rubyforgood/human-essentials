class AddPhoneNumberToPartners < ActiveRecord::Migration[8.1]
  def change
    add_column :partners, :phone_number, :string
  end
end
