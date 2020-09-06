class AddTimeframeToDistributions < ActiveRecord::Migration[6.0]
  def change
    add_column :distributions, :issued_at_end, :datetime
    add_column :distributions, :issued_at_timeframe_enabled, :boolean, default: false 
  end
end
