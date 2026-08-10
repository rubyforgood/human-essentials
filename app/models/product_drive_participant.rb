# == Schema Information
#
# Table name: product_drive_participants
#
#  id              :integer          not null, primary key
#  address         :string
#  business_name   :string
#  comment         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

class ProductDriveParticipant < ApplicationRecord
  has_paper_trail
  include Filterable
  include Geocodable
  include Provideable

  has_many :donations, inverse_of: :product_drive_participant, dependent: :destroy

  validates :phone, presence: { message: "Must provide a phone or an e-mail" }, if: proc { |pdp| pdp.email.blank? }
  validates :email, presence: { message: "Must provide a phone or an e-mail" }, if: proc { |pdp| pdp.phone.blank? }
  validates :contact_name, presence: { message: "Must provide a name or a business name" }, if: proc { |pdp| pdp.business_name.blank? }
  validates :business_name, presence: { message: "Must provide a name or a business name" }, if: proc { |pdp| pdp.contact_name.blank? }
  validates :comment, length: { maximum: 500 }

  # Orders on the name the drop-downs actually show - `display_name`, which is
  # `business_name` falling back to `contact_name` - rather than on the database
  # collation, which is not the same everywhere: a `C.UTF-8` cluster puts every
  # capitalised name before every lowercase one and the `en_US.utf8` image CI
  # runs does not. Runs of digits are zero padded so that they compare by value
  # and "Store 9" comes before "Store 10".
  #
  # Written as a literal because the schema is maintained as `schema.rb`, which
  # carries neither a Postgres function nor an ICU collation - both would
  # disappear on `db:schema:load`.
  DISPLAY_NAME_ORDER = Arel.sql(<<~SQL.squish)
    (SELECT string_agg(
              CASE WHEN chunk[1] ~ '^[0-9]' THEN lpad(chunk[1], 20, '0') ELSE chunk[1] END,
              '' ORDER BY idx)
       FROM regexp_matches(
              lower(coalesce(NULLIF(business_name, ''), contact_name, '')),
              '[0-9]+|[^0-9]+', 'g')
       WITH ORDINALITY AS chunks(chunk, idx))
  SQL

  scope :alphabetized, -> { order(DISPLAY_NAME_ORDER) }
  scope :by_business_name, ->(business_name) { where("business_name ILIKE ?", "%#{business_name}%") }
  scope :by_contact_name, ->(contact_name) { where("contact_name ILIKE ?", "%#{contact_name}%") }
  scope :with_volumes, -> {
    left_joins(donations: :line_items)
      .select("product_drive_participants.*, SUM(COALESCE(line_items.quantity, 0)) AS volume")
      .group(:id)
  }

  def volume
    donations.map { |d| d.line_items.total }.reduce(:+)
  end

  def volume_by_product_drive(product_drive_id)
    donations.by_product_drive(product_drive_id).map { |d| d.line_items.total }.sum
  end

  def donation_source_view
    return if contact_name.blank?

    "#{contact_name} (participant)"
  end

  def display_name
    business_name.presence || contact_name
  end
end
