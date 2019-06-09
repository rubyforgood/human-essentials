class AddManufacturerToDonation < ActiveRecord::Migration[5.2]
  def change
    add_reference :donations, :manufacturer, foreign_key: true
  end
end
