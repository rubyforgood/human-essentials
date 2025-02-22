class RemoveForBanksAndForPartnersFromQuestions < ActiveRecord::Migration[7.2]
  def up
    Question.where(for_partners: true, for_banks: false).delete_all
    safety_assured do
      remove_column :questions, :for_banks
      remove_column :questions, :for_partners
    end
  end

  def down
    add_column :questions, :for_banks, :boolean, null: false, default: true
    add_column :questions, :for_partners, :boolean, null: false, default: false
  end
end
