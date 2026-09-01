# The parser that splits a freeform address into four columns.
#
# This is the part of the change that can lose data, so it is tested against the shapes actually in
# the database rather than against tidy invented ones. The rule it must never break: **whatever the
# parser cannot place stays in `street`**, so the worst outcome is a record someone has to finish by
# hand, never a record missing text somebody typed.
RSpec.describe StructuredAddress do
  describe ".parse_address" do
    subject(:parse) { Vendor.parse_address(text) }

    context "a full US address" do
      let(:text) { "1500 Remount Road, Front Royal, VA 22630" }

      it "splits into four parts" do
        expect(parse).to eq(street: "1500 Remount Road", city: "Front Royal",
          state: "VA", zipcode: "22630")
      end
    end

    context "with ZIP+4" do
      let(:text) { "571 Macejkovic Motorway, Alysechester, KS 91888-2366" }

      it "keeps all nine digits" do
        expect(parse[:zipcode]).to eq("91888-2366")
        expect(parse[:city]).to eq("Alysechester")
      end
    end

    context "a street and city with no comma between them" do
      # Every vendor in the seed database is written this way, and it is the case a parser gets
      # wrong by being clever: there is no way to know that "Vincentshire" is the city and not the
      # end of the street name, so it does not guess.
      let(:text) { "3035 Mattie Isle Vincentshire, MA 11923-5457" }

      it "takes the state and ZIP it can be sure of, and leaves the rest whole" do
        expect(parse).to eq(street: "3035 Mattie Isle Vincentshire", city: "",
          state: "MA", zipcode: "11923-5457")
      end
    end

    context "text that is not an address at all" do
      let(:text) { "Unknown" }

      it "keeps it, in street" do
        expect(parse).to eq(street: "Unknown", city: "", state: "", zipcode: "")
      end
    end

    context "a two-letter word at the end that is not a state" do
      let(:text) { "12 Sesame St" }

      it "is not mistaken for one" do
        # "St" is not in the 51, so it stays part of the street. This is why the parser checks the
        # code against the list instead of trusting any two letters at the end.
        expect(parse[:state]).to eq("")
        expect(parse[:street]).to eq("12 Sesame St")
      end
    end

    it "handles an empty address" do
      expect(Vendor.parse_address(nil)).to eq(street: "", city: "", state: "", zipcode: "")
      expect(Vendor.parse_address("  ")).to eq(street: "", city: "", state: "", zipcode: "")
    end

    it "uppercases a lowercase state code and tidies runs of whitespace" do
      expect(Vendor.parse_address("12  Main  St.,  Pawnee,  in  12345"))
        .to eq(street: "12 Main St.", city: "Pawnee", state: "IN", zipcode: "12345")
    end

    it "never throws any of the text away" do
      # The invariant, stated as one property over every shape above: each word of the original
      # still appears somewhere in the parsed result.
      ["1500 Remount Road, Front Royal, VA 22630",
        "3035 Mattie Isle Vincentshire, MA 11923-5457",
        "Unknown", "12 Sesame St", "2345 NE Some St., Pawnee, IN 12345"].each do |original|
        parts = Vendor.parse_address(original).values.join(" ")
        original.split(/[,\s]+/).each do |word|
          expect(parts).to include(word), "#{original.inspect} lost #{word.inspect}"
        end
      end
    end
  end

  describe "#address" do
    it "composes the four parts the way Geocodable and the PDFs expect" do
      vendor = Vendor.new(street: "1500 Remount Road", city: "Front Royal",
        state: "VA", zipcode: "22630")
      expect(vendor.address).to eq("1500 Remount Road, Front Royal, VA 22630")
    end

    it "leaves no stray commas when only part of it is filled in" do
      expect(Vendor.new(street: "Unknown").address).to eq("Unknown")
      expect(Vendor.new(city: "Pawnee", state: "IN").address).to eq("Pawnee, IN")
    end

    it "round-trips a full address" do
      original = "1500 Remount Road, Front Royal, VA 22630"
      expect(Vendor.new(address: original).address).to eq(original)
    end
  end

  describe "#address=" do
    it "is what lets a CSV keep one address column" do
      # `import_csv` does `new(row.to_hash)`, so this assignment is the whole reason a bank's saved
      # template file still works after the split.
      vendor = Vendor.new(address: "1500 Remount Road, Front Royal, VA 22630")
      expect(vendor.street).to eq("1500 Remount Road")
      expect(vendor.state).to eq("VA")
    end
  end

  describe "#address_changed?" do
    it "reports a change to any part, because Geocodable asks it" do
      vendor = create(:vendor)
      expect(vendor.address_changed?).to be false
      vendor.city = "Elsewhere"
      expect(vendor.address_changed?).to be true
    end
  end
end
