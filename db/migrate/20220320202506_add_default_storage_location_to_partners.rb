class AddDefaultStorageLocationToPartners < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :partners, :default_storage_location, index: {algorithm: :concurrently}
  end
end
