if Rails.env.local?   # development + test: committed non-prod keys (like secret_key_base in secrets.yml)
  primary_key = "YCEmkDIf91rP301UjZSXb8QwB43wU9qK"
  key_derivation_salt = "fZVRM9z52VcYVlFG1UikohNjZgcqFX8z"
else                  # production/staging: ENV.fetch (no default) => boot fails loudly if unset
  primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY")
  key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT")
end

ActiveRecord::Encryption.configure(
  primary_key: primary_key,
  key_derivation_salt: key_derivation_salt,
  # Bridge for migrating existing plaintext rows: lets reads of not-yet-backfilled
  # columns work instead of raising. Flip to false (follow-up) after prod backfill.
  support_unencrypted_data: true
)
