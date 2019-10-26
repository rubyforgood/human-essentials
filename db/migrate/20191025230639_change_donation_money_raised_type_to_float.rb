class ChangeDonationMoneyRaisedTypeToFloat < ActiveRecord::Migration[6.0]
  def change
    change_column :donations, :money_raised, :float
  end
end
