class RenameDiaperBudgetToEssentialsBudget < ActiveRecord::Migration[7.0]
  def change
    safety_assured {
      rename_column :partner_profiles, :diaper_budget, :essentials_budget
    }
  end
end
