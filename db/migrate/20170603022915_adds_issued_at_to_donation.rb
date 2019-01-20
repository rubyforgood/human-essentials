class AddsIssuedAtToDonation < ActiveRecord::Migration[5.0]
  # doin this old-school because we need to initialize it programmatically
  def up
  	add_column :donations, :issued_at, :datetime
  	Donation.all.each do |d|
  		d.issued_at = d.created_at
  		d.save
  	end
    Donation.reset_column_information
  end

  def down
  	remove_column :donations, :issued_at
  end
end
