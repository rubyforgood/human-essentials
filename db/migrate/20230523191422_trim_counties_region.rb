class TrimCountiesRegion < ActiveRecord::Migration[7.0]
  def change
    County.find_each do |county|
      county.region = county.region.strip
      county.save!
    end
  end
end
