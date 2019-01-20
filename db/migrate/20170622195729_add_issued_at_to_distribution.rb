class AddIssuedAtToDistribution < ActiveRecord::Migration[5.1]
  # doin this old-school because we need to initialize it programmatically
  def up
    add_column :distributions, :issued_at, :datetime
    Distribution.all.each do |d|
      d.issued_at = d.created_at
      d.save
    end
    Distribution.reset_column_information
  end

  def down
    remove_column :distributions, :issued_at
  end
end
