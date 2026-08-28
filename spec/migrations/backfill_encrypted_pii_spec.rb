require "rails_helper"
require Rails.root.join("db/migrate/20260703191552_backfill_encrypted_pii")

RSpec.describe BackfillEncryptedPii, type: :migration do
  let(:connection) { ActiveRecord::Base.connection }
  let(:migration) { described_class.new }

  let(:family) { create(:partners_family) }
  let(:child) { create(:partners_child, family: family) }
  let(:participant) { create(:product_drive_participant) }
  let(:profile) { create(:partner_profile) }

  # Rows as production holds them: written before `encrypts` existed, so still plaintext.
  # They have to be seeded with raw SQL, since the models would encrypt them on the way in.
  def write_plaintext(record, values)
    assignments = values.map { |column, value| "#{column} = #{connection.quote(value)}" }.join(", ")
    connection.execute("UPDATE #{record.class.table_name} SET #{assignments} WHERE id = #{record.id}")
    record.reload
  end

  def stored(record, column)
    connection.select_value("SELECT #{column} FROM #{record.class.table_name} WHERE id = #{record.id}")
  end

  it "encrypts the rows that are still plaintext, keeping their values" do
    write_plaintext(child, date_of_birth: "1990-03-04")
    write_plaintext(family, guardian_phone: "555-1234")
    write_plaintext(participant, phone: "555-9876", email: "donor@example.com")
    write_plaintext(profile, primary_contact_email: "contact@example.com", pick_up_phone: "555-4444")

    migration.up

    expect(stored(child, :date_of_birth)).to start_with('{"p":')
    expect(stored(family, :guardian_phone)).to start_with('{"p":')
    expect(stored(participant, :email)).to start_with('{"p":')
    expect(stored(profile, :primary_contact_email)).to start_with('{"p":')

    expect(child.reload.date_of_birth).to eq(Date.new(1990, 3, 4))
    expect(family.reload.guardian_phone).to eq("555-1234")
    expect(participant.reload.phone).to eq("555-9876")
    expect(participant.reload.email).to eq("donor@example.com")
    expect(profile.reload.primary_contact_email).to eq("contact@example.com")
    expect(profile.pick_up_phone).to eq("555-4444")
  end

  it "leaves rows that are already encrypted untouched" do
    # The factories write through the models, so these rows are encrypted already. Encryption is
    # non-deterministic: if the migration re-encrypted them, the ciphertext would come out different.
    ciphertext = stored(child, :date_of_birth)

    expect { migration.up }.not_to change { stored(child, :date_of_birth) }.from(ciphertext)
  end

  it "picks up where a failed run stopped" do
    encrypted_child = child
    plaintext_child = create(:partners_child, family: family)
    write_plaintext(plaintext_child, date_of_birth: "1985-12-31")
    ciphertext = stored(encrypted_child, :date_of_birth)

    migration.up

    expect(stored(encrypted_child, :date_of_birth)).to eq(ciphertext)
    expect(plaintext_child.reload.date_of_birth).to eq(Date.new(1985, 12, 31))
  end

  it "leaves a missing value null" do
    write_plaintext(child, date_of_birth: nil)

    migration.up

    expect(stored(child, :date_of_birth)).to be_nil
  end
end
