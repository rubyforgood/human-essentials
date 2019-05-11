# This unifies the language about "Donation Sites". 
class UpdateDonationSources < ActiveRecord::Migration[5.1]
  def change
    execute("update donations set source = 'Donation Site' where source = 'Donation Pickup Location'")
  end
end
