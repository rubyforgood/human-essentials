# Keys come from the environment everywhere, so there is no env-specific branch here. Development
# and test read them from the committed .env.development and .env.test, which dotenv loads before
# initializers run. Production and staging get them from the real environment, and ENV.fetch has no
# default, so a missing key fails the boot loudly instead of silently writing data that cannot be
# read back later.
ActiveRecord::Encryption.configure(
  primary_key: ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY"),
  key_derivation_salt: ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT"),

  # Bridge for migrating existing plaintext rows: lets reads of not-yet-backfilled
  # columns work instead of raising. Flip to false (follow-up) after prod backfill.
  support_unencrypted_data: true
)
