class ChangeDonationMoneyRaisedTypeToFloat < ActiveRecord::Migration[6.0]
  def change
    reversible do |change|
      change.up do
        change_column :donations, :money_raised, :decimal, scale: 2
      end

      change.down do
        change_column :donations, :money_raised, :integer
      end
    end
  end
end
