# Partners have a status
class AddStatusToPartner < ActiveRecord::Migration[5.2]
  def change
    add_column :partners, :status, :string
  end
end
