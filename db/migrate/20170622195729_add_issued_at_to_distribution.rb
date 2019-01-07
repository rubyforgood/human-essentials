class AddIssuedAtToDistribution < ActiveRecord::Migration[5.1]
  class MigrationDistribution < ActiveRecord::Base
    self.table_name = :distributions
  end

  # doin this old-school because we need to initialize it programmatically
  def up
    add_column :distributions, :issued_at, :datetime
    MigrationDistribution.all.each do |d|
      d.issued_at = d.created_at
      d.save
    end
    MigrationDistribution.reset_column_information
  end

  def down
    remove_column :distributions, :issued_at
  end
end
