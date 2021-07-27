class AddStatusInDiaperBaseToPartner < ActiveRecord::Migration[6.0]
  def change
    add_column :partners, :status_in_diaper_base, :string
  end
end
