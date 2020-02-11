# The stakeholder wanted the ability to track dollar values in donations, for reporting purposes
class AddDollarsRaisedToDonations < ActiveRecord::Migration[5.2]
  def change
    add_column :donations, :money_raised, :integer
  end
end
