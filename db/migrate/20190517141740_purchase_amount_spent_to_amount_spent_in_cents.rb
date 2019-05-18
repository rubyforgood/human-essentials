class PurchaseAmountSpentToAmountSpentInCents < ActiveRecord::Migration[5.2]
  def self.up
    rename_column :purchases, :amount_spent, :amount_spent_in_cents
  end

  def self.down
    rename_column :items, :amount_spent_in_cents, :amount_spent
  end
end
