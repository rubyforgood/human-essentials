# The Stakeholder wanted the ability to set an alternate timestamp for when the distribution actually
# leaves. :created_at and :updated_at were too restrictive
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
