class AddCategoriesToPurchases < ActiveRecord::Migration[6.1]
  def change
    add_monetize :purchases, :diapers_money, currency: { present: false }
    add_monetize :purchases, :adult_incontinence_money, currency: { present: false }
    add_monetize :purchases, :other_money, currency: { present: false }
    change_column_default :purchases, :diapers_money_cents, from: nil, to: 0
    change_column_default :purchases, :adult_incontinence_money_cents, from: nil, to: 0
    change_column_default :purchases, :other_money_cents, from: nil, to: 0
  end
end
