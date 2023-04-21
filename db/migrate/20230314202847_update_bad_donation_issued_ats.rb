class UpdateBadDonationIssuedAts < ActiveRecord::Migration[7.0]
  def up
    Donation.unscoped.where("issued_at <  ?","2000-01-01").
      update_all('issued_at=created_at, updated_at=NOW()')
  end

end
