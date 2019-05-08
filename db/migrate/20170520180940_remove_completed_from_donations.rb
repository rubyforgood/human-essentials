# We realized that "completing" a donation was tautological - the completion of a donation
# occurred when the application finished copying the inventory in; user interaction was unnecessary
# and so there was no need for tracking that state
class RemoveCompletedFromDonations < ActiveRecord::Migration[5.0]
  def change
    remove_column :donations, :completed
  end
end
