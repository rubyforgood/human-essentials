class UpdateBadDistributionIssuedAts < ActiveRecord::Migration[7.0]
  def up
    Distribution.unscoped.where("issued_at <  ?","2000-01-01").
      update_all('issued_at=created_at, updated_at=NOW()')
  end
end
