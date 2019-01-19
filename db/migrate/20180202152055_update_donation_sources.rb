class UpdateDonationSources < ActiveRecord::Migration[5.1]
  class MigrationDonation < ActiveRecord::Base
    self.table_name = :donations
  end

  def up
    MigrationDonation.where(source: 'Donation Pickup Location').update_all(source: 'Donation Site')
  end

  def down
    MigrationDonation.where(source: 'Donation Site').update_all(source: 'Donation Pickup Location')
  end
end
