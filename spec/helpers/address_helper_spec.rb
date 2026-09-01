require "json"

# One definition of what an address field is, and the audit that enforces it agreeing with it.
#
# Seven screens collect an address. Before this they did it in five shapes: `state` was a 52-option
# select on one form and a free text box on another, `program_zip_code` was an integer column so it
# rendered as `type="number"`, the same box was labelled "Street", "Street address" and
# "Address (line 1)", and not one of the fields carried `autocomplete`.
RSpec.describe AddressHelper, type: :helper do
  describe "#address_field" do
    it "gives every part the autocomplete token a browser fills it from" do
      # WCAG 1.3.5 Identify Input Purpose (AA). The tokens are not interchangeable: `street-address`
      # is a whole multi-line address, so a two-line address uses `address-line1`/`address-line2`,
      # and city and state are named by administrative level rather than by American words.
      expect(helper.address_field(:street)[:input_html][:autocomplete]).to eq("street-address")
      expect(helper.address_field(:line1)[:input_html][:autocomplete]).to eq("address-line1")
      expect(helper.address_field(:line2)[:input_html][:autocomplete]).to eq("address-line2")
      expect(helper.address_field(:city)[:input_html][:autocomplete]).to eq("address-level2")
      expect(helper.address_field(:state)[:input_html][:autocomplete]).to eq("address-level1")
      expect(helper.address_field(:zip)[:input_html][:autocomplete]).to eq("postal-code")
    end

    it "offers the states as a list rather than a box to type into" do
      field = helper.address_field(:state)
      expect(field[:collection]).to eq(helper.us_states)
      expect(field[:collection].size).to eq(51)
    end

    it "asks for a ZIP as text with a numeric keypad, never as a number" do
      # `type="number"` drops the leading zero on every ZIP in New England and Puerto Rico and
      # refuses ZIP+4 outright. `inputmode` still brings the keypad up on a phone.
      html = helper.address_field(:zip)[:input_html]
      expect(html[:inputmode]).to eq("numeric")
      expect(html).not_to include(:as)
      expect("02108").to match(Regexp.new("\\A#{html[:pattern]}\\z"))
      expect("39428-1234").to match(Regexp.new("\\A#{html[:pattern]}\\z"))
      expect("1234").not_to match(Regexp.new("\\A#{html[:pattern]}\\z"))
    end

    it "says out loud when an address belongs to someone other than the person typing" do
      # A partner entering a client's ZIP is not entering their own, and WCAG 1.3.5 is about the
      # user's own information -- autofilling the caseworker's address into a family record would
      # be worse than not filling it. `off` declares that; a missing attribute says nothing.
      expect(helper.address_field(:zip, third_party: true)[:input_html][:autocomplete]).to eq("off")
    end

    it "lets a screen qualify the label without inventing new words for the part" do
      expect(helper.address_field(:zip)[:label]).to eq("ZIP code")
      expect(helper.address_field(:zip, label: "Guardian ZIP code")[:label]).to eq("Guardian ZIP code")
    end
  end

  # The audit carries the same table in JavaScript, because it runs in a browser and cannot ask
  # Ruby. Two copies of a table is how they drift, so this is the thing that stops it: change one
  # and this fails.
  it "agrees with the table in bin/design/address-audit.js" do
    source = Rails.root.join("bin/design/address-audit.js").read
    block = source[/const ROLES = \{(.*?)\n\};/m, 1]
    expect(block).to be_present, "could not find ROLES in address-audit.js"

    in_js = block.scan(/^\s*(\w+):\s*\{ label: "([^"]+)", token: "([^"]+)" \}/)
      .to_h { |role, label, token| [role.to_sym, {label: label, autocomplete: token}] }

    # `whole` is the audit's name for a single box holding an entire address, which the helper has
    # no separate entry for -- it is `street` under another name, and the audit needs to tell them
    # apart to check the label.
    expect(in_js.except(:whole)).to eq(AddressHelper::ADDRESS_FIELDS)
    expect(in_js[:whole][:autocomplete]).to eq(AddressHelper::ADDRESS_FIELDS[:street][:autocomplete])
  end
end
