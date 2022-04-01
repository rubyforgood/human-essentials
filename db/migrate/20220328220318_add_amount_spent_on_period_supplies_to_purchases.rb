class AddAmountSpentOnPeriodSuppliesToPurchases < ActiveRecord::Migration[6.1]
  def change
    safety_assured { add_monetize :purchases, :amount_spent_on_period_supplies, currency: { present: false } }
    change_column_default :purchases, :amount_spent_on_period_supplies_cents, from: nil, to: 0
  end
end
