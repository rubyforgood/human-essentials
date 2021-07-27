# This migration comes from active_storage (originally 20190112182829)
class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[6.0]
  def up
    unless column_exists?(:active_storage_blobs, :service_name)
      add_column :active_storage_blobs, :service_name, :string

      # this migration was generated, so ignore this rubocop rule
      # rubocop:disable Rails/SkipsModelValidations
      if configured_service = ActiveStorage::Blob.service.name
        ActiveStorage::Blob.unscoped.update_all(service_name: configured_service)
      end
      # rubocop:enable Rails/SkipsModelValidations

      safety_assured do
        change_column :active_storage_blobs, :service_name, :string, null: false
      end
    end
  end

  def down
    remove_column :active_storage_blobs, :service_name
  end
end
