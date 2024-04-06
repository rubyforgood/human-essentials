class RestoreDonationSites < ActiveRecord::Migration[7.0]
  def up
    DonationSite.all.each do |site|
      site.update!(active: true)
    end
  end

  def down

  end
end
