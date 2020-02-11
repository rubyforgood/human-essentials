# We realized that "Distribution" made the intent clearer 
class RenameTicketsToDistributions < ActiveRecord::Migration[5.0]
  def change
    rename_table :tickets, :distributions
  end
end
