class UpdateBadDistributionIssuedAts < ActiveRecord::Migration[7.0]
  def up
    Distribution.unscoped.where("issued_at <  ?","2000-01-01").find_each do |dist|
      # Using update_attribute, rather than update! because some of the distributions
      # will not validate for other reasons (storage locations missing items)
      dist.update_attribute(:issued_at, dist.created_at)
    end
  end
end
