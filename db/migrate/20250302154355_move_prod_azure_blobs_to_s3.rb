class MoveProdAzureBlobsToS3 < ActiveRecord::Migration[7.2]
  # https://stackoverflow.com/questions/71699789/activestorage-transfer-all-assets-from-one-bucket-to-another-bucket
  def up
    return unless Rails.env.production?

    source_service = ActiveStorage::Blob.services.fetch(:azure)
    destination_service = ActiveStorage::Blob.services.fetch(:amazon)

    ActiveStorage::Blob.where(service_name: source_service.name).find_each do |blob|
      key = blob.key

      unless source_service.exist?(key)
        Rails.logger.error("I can't find blob #{blob.id} (#{key})")
        next
      end

      unless destination_service.exist?(key)
        source_service.open(blob.key, checksum: blob.checksum) do |file|
          destination_service.upload(blob.key, file, checksum: blob.checksum)
        end
      end
      blob.update_columns(service_name: destination_service.name)
    end

  end

  def down
    raise IrreversibleMigration
  end
end
