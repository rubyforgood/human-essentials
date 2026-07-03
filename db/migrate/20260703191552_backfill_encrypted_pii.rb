class BackfillEncryptedPii < ActiveRecord::Migration[8.0]
  # `encrypts` only encrypts new writes, so existing rows stay plaintext until re-saved.
  # This re-encrypts them in place. `record.encrypt` uses update_columns (no validations,
  # callbacks, timestamps or paper_trail), and relies on
  # config.active_record.encryption.support_unencrypted_data = true to read the plaintext.
  #
  # No wrapping transaction: each row commits on its own, so a big table doesn't hold one
  # long transaction/lock and a failed run keeps its progress (encrypt is idempotent).
  disable_ddl_transaction!

  MODELS = [Partners::Child, Partners::AuthorizedFamilyMember, Partners::Family, ProductDriveParticipant].freeze

  def up
    MODELS.each do |model|
      model.find_in_batches do |batch|
        batch.each(&:encrypt)
        sleep(0.1) # throttle prod DB load (~40-50k rows); matches BackfillItemReportingCategoryField
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
