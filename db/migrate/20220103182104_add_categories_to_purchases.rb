class AddCategoriesToPurchases < ActiveRecord::Migration[6.1]
  def change
    safety_assured { add_monetize :purchases, :amount_spent_on_diapers, currency: { present: false } }
    safety_assured { add_monetize :purchases, :amount_spent_on_adult_incontinence, currency: { present: false } }
    safety_assured { add_monetize :purchases, :amount_spent_on_other, currency: { present: false } }
    change_column_default :purchases, :amount_spent_on_diapers_cents, from: nil, to: 0
    change_column_default :purchases, :amount_spent_on_adult_incontinence_cents, from: nil, to: 0
    change_column_default :purchases, :amount_spent_on_other_cents, from: nil, to: 0
  end
end
