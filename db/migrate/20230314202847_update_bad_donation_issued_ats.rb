class UpdateBadDonationIssuedAts < ActiveRecord::Migration[7.0]
  Donation.unscoped.where("issued_at <  ?","2000-01-01").find_each do |donation|
    donation.update_attribute(:issued_at, donation.created_at)
  end
end
