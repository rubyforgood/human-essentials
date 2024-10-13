class BackfillVendorBusinessNameFromContact < ActiveRecord::Migration[7.1]
  def change
    Vendor.where(business_name: [nil, ""]).update_all('business_name = contact_name')
  end
end
