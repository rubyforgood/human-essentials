require "rails_helper"
require Rails.root.join("db/migrate/20260703191550_encrypt_dates_of_birth")
require Rails.root.join("db/migrate/20260703191552_backfill_encrypted_pii")

# `date_of_birth` is rewritten from `date` to `text` in place, so a lossy conversion would destroy
# the original value with nothing left to recover it from. These specs rewind the schema to the
# pre-migration state, seed the plaintext dates production still holds, then run the real migrations
# against real Postgres and check every date survives the round trip.
#
# Transactional fixtures roll the DDL back afterwards (Postgres DDL is transactional).
RSpec.describe EncryptDatesOfBirth, type: :migration do
  let(:connection) { ActiveRecord::Base.connection }
  let(:models) { [Partners::Child, Partners::AuthorizedFamilyMember] }

  let(:dates) do
    [
      Date.new(2020, 2, 29),  # leap day
      Date.new(1990, 3, 4),   # day and month are both valid months: silently swappable
      Date.new(1985, 12, 31), # day cannot be a month: parses as nil rather than swapping
      Date.new(1900, 1, 1)    # distant past
    ]
  end

  let(:family) { create(:partners_family) }
  # Seeded with no date of birth, so nothing is encrypted before the schema is rewound.
  let(:children) { dates.map { create(:partners_child, family: family, date_of_birth: nil) } }
  let(:members) do
    dates.map { family.authorized_family_members.create!(first_name: "A", last_name: "B") }
  end

  before do
    reset_columns!
    children
    members

    # Rewind to the pre-migration schema and fill in the legacy plaintext dates. They have to be
    # written with raw SQL: through the models, `encrypts` would encrypt them on the way in.
    models.each do |model|
      connection.change_column model.table_name, :date_of_birth, :date, using: "date_of_birth::date"
    end
    reset_columns!
    children.zip(dates) { |child, date| write_legacy_date("children", child, date) }
    members.zip(dates) { |member, date| write_legacy_date("authorized_family_members", member, date) }
  end

  after { reset_columns! }

  def reset_columns!
    models.each(&:reset_column_information)
  end

  def write_legacy_date(table, record, date)
    connection.execute(<<~SQL)
      UPDATE #{table} SET date_of_birth = DATE '#{date.iso8601}' WHERE id = #{record.id}
    SQL
  end

  def run_migrations!
    described_class.new.up
    BackfillEncryptedPii.new.up
    reset_columns!
  end

  it "preserves every date of birth through the conversion and the backfill" do
    run_migrations!

    expect(children.map { |child| child.reload.date_of_birth }).to eq(dates)
    expect(members.map { |member| member.reload.date_of_birth }).to eq(dates)
  end

  it "still reads the dates back as dates, not as strings" do
    run_migrations!

    expect(children.first.reload.date_of_birth).to be_a(Date)
  end

  it "leaves a missing date of birth null rather than inventing one" do
    childless_date = create(:partners_child, family: family, date_of_birth: nil)

    run_migrations!

    expect(childless_date.reload.date_of_birth).to be_nil
  end

  it "stores the dates as ciphertext" do
    run_migrations!

    stored = connection.select_values("SELECT date_of_birth FROM children WHERE date_of_birth IS NOT NULL")
    expect(stored).to all(start_with('{"p":'))
    expect(stored.join).not_to include("1990-03-04")
  end

  it "converts the dates identically under a non-ISO DateStyle" do
    # This is what `using: to_char(...)` buys. A bare `change_column` serializes the date with the
    # server's DateStyle, so under `SQL, MDY` 1990-03-04 is written as "03/04/1990" and Ruby, which
    # reads ambiguous dates day-first, hands the backfill April 3rd to encrypt.
    connection.execute("SET DateStyle TO 'SQL, MDY'")

    run_migrations!

    expect(children.map { |child| child.reload.date_of_birth }).to eq(dates)
  end
end
