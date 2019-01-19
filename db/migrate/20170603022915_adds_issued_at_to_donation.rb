class AddsIssuedAtToDonation < ActiveRecord::Migration[5.0]
  class MigrationDonation < ActiveRecord::Base
    self.table_name = :donations
  end

  # doin this old-school because we need to initialize it programmatically
  def up
  	add_column :donations, :issued_at, :datetime
  	MigrationDonation.all.each do |d|
  		d.issued_at = d.created_at
  		d.save
  	end
    MigrationDonation.reset_column_information
  end

  def down
  	remove_column :donations, :issued_at
  end
end
