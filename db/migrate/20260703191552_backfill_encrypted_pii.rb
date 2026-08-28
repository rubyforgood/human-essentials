class BackfillEncryptedPii < ActiveRecord::Migration[8.0]
  # `encrypts` only encrypts new writes, so existing rows stay plaintext until re-saved.
  # This re-encrypts them in place. `record.encrypt` uses update_columns (no validations,
  # callbacks, timestamps or paper_trail), and relies on
  # config.active_record.encryption.support_unencrypted_data = true to read the plaintext.
  #
  # No wrapping transaction: each row commits on its own, so a big table doesn't hold one long
  # transaction/lock, and a run that fails halfway keeps the rows it already encrypted.
  disable_ddl_transaction!

  MODELS = [
    Partners::Child,
    Partners::AuthorizedFamilyMember,
    Partners::Family,
    Partners::Profile,
    ProductDriveParticipant
  ].freeze

  def up
    MODELS.each do |model|
      model.find_in_batches do |batch|
        batch.reject { |record| encrypted?(record) }.each(&:encrypt)
        sleep(0.1) # throttle prod DB load (~40-50k rows); matches BackfillItemReportingCategoryField
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # `encrypt` writes unconditionally, and the encryption is non-deterministic, so re-encrypting an
  # already-encrypted row rewrites it with fresh ciphertext: same value, wasted write. Skipping
  # those rows is what lets a run that failed halfway be re-run and only do what is left.
  #
  # Ciphertext is opaque to Postgres, so there is no scope for this: the check is per record.
  # A blank value counts as done, since there is nothing to encrypt.
  def encrypted?(record)
    record.class.encrypted_attributes.all? do |attribute|
      value = record.read_attribute_before_type_cast(attribute)
      value.blank? || record.encrypted_attribute?(attribute)
    end
  end
end
