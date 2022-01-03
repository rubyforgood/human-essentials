class AddCategoriesToPurchases < ActiveRecord::Migration[6.1]
  def change
    add_column :purchases, :diapers_money_in_cents, :integer
    add_column :purchases, :adult_incontinence_money_in_cents, :integer
    add_column :purchases, :other_money_in_cents, :integer
    change_column_default :purchases, :diapers_money_in_cents, 0
    change_column_default :purchases, :adult_incontinence_money_in_cents, 0
    change_column_default :purchases, :other_money_in_cents, 0
  end
end
