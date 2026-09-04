# An address kept as four columns, with a `#address` that reads and writes the whole thing.
#
# `Vendor`, `DonationSite`, `ProductDriveParticipant` and `StorageLocation` each stored one freeform
# `address` string, where `Organization` has always stored `street`, `city`, `state` and `zipcode`
# and composed `#address` from them. Five screens asking for the same thing two different ways --
# reported on the vendor form, and the reason nobody can list donation sites by state.
#
# This is `Organization`'s pattern, extracted, plus the one thing `Organization` never needed:
#
#   * **`#address` reads.** `"street, city, ST zip"`, the format `Geocodable` geocodes and the four
#     PDFs print. Every existing caller keeps working without knowing the storage changed.
#   * **`#address=` writes**, by parsing. That is what lets the CSV importers keep taking a single
#     `address` column -- `import_csv` does `new(row.to_hash)`, so a bank's saved template file is
#     still valid. See "Address fields" in design.md for why that mattered more than a tidier CSV.
#
# **Parsing never discards anything.** Anything the parser cannot place goes into `street` whole, so
# the worst case is a record whose city and state need filling in by hand -- not a record missing
# the text somebody typed. Measured against the seed database, 10 of 18 rows parse into all four
# parts and the other 8 keep their text in `street`.
module StructuredAddress
  extend ActiveSupport::Concern

  # Five digits, or five and four, at the very end of the string.
  ZIP = /\s*(\d{5}(?:-\d{4})?)\z/

  included do
    # The old freeform column. Reads and writes go through the four new ones; `#address` below
    # composes it back for the geocoder, the PDFs and the CSV exports.
    #
    # **The column itself is already gone**, dropped by `20260901200000`, so on any database that
    # has run that migration this line does nothing. It stays anyway, and deliberately.
    #
    # Un-ignore it against a database where the drop has *not* run and ActiveRecord generates an
    # `address` attribute accessor, which collides with the `#address` method defined below.
    # Depending on load order the raw, empty column can win -- so every address on those four models
    # renders blank, with nothing raising. A silent wrong answer is the worst kind, and it costs one
    # line to prevent.
    #
    # Safe to delete once `20260901200000` has been deployed everywhere. There is no hurry: the only
    # standing cost is that a *new* `address` column added to these models for some other purpose
    # would be hidden without a word. If that ever happens, this line is the reason.
    #
    # Kept as a code comment rather than a to-do entry, on purpose -- it is a fact about this line,
    # and it belongs where someone reading the line will find it. History in docs/migration-map.md.
    self.ignored_columns += ["address"]
  end

  class_methods do
    # `Vendor.parse_address(...)`, for callers that have a model to hand.
    def parse_address(text) = StructuredAddress.parse(text)
  end

  # Pulls "street, city, ST zip" apart, from the end inwards, because the end is the part with a
  # shape. A ZIP is unmistakable and a state is one of 51 known codes; the street and city are
  # whatever is left, so they are never guessed at from their contents.
  #
  # Returns the four parts, with everything unrecognised left in `street`.
  #
  # A module function rather than only a class method, so nothing needs a model to split an address.
  def self.parse(text)
    rest = text.to_s.strip.gsub(/\s+/, " ")
    return {street: "", city: "", state: "", zipcode: ""} if rest.empty?

    zipcode = rest.slice!(ZIP) ? Regexp.last_match(1) : ""
    rest = rest.sub(/[,\s]+\z/, "")

    state = ""
    if (found = rest[/(?:\A|[,\s])([A-Za-z]{2})\z/, 1]) && AddressHelper::STATE_CODES.include?(found.upcase)
      state = found.upcase
      rest = rest[0...-found.length].sub(/[,\s]+\z/, "")
    end

    # The last comma separates the city from the street. No comma means no city was written down,
    # and inventing one out of the last two words is how a parser turns "3035 Mattie Isle
    # Vincentshire" into a street called "3035 Mattie" -- so the whole thing stays as the street.
    street, city = rest.include?(",") ? rest.rpartition(",").values_at(0, 2) : [rest, ""]

    {street: street.strip, city: city.strip, state: state, zipcode: zipcode}
  end

  # The whole address on one line, which is what `Geocodable` geocodes and the PDFs print.
  # `compact_blank` so a record with only a street does not come out as ", , ".
  def address
    state_and_zip = [state, zipcode].compact_blank.join(" ")
    [street, city, state_and_zip].compact_blank.join(", ")
  end

  # Assigning the whole thing splits it. The CSV importers and every existing factory do this.
  def address=(text)
    parse = self.class.parse_address(text)
    self.street = parse[:street]
    self.city = parse[:city]
    self.state = parse[:state]
    self.zipcode = parse[:zipcode]
  end

  # `Geocodable` runs `after_validation ... if: obj.address_changed?`, and there is no `address`
  # attribute to have changed any more.
  def address_changed?
    street_changed? || city_changed? || state_changed? || zipcode_changed?
  end
end
