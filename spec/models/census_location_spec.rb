RSpec.describe CensusLocation do
  before { create_census_locations }

  describe ".locate" do
    def label(query) = described_class.locate(query)&.label

    it "finds a city written every way people write one" do
      ["Dayton, OH", "dayton oh", "Dayton OH", "Dayton, Ohio", "DAYTON OHIO", " Dayton ,  OH "].each do |query|
        expect(label(query)).to eq("Dayton, OH"), "#{query.inspect} did not find Dayton"
      end
    end

    it "treats Saint and St. as the same word" do
      expect(label("Saint Petersburg, FL")).to eq("St. Petersburg, FL")
      expect(label("St Petersburg FL")).to eq("St. Petersburg, FL")
    end

    it "finds a ZIP code, with or without the four-digit suffix" do
      expect(label("45402")).to eq("45402")
      expect(label("45402-1234")).to eq("45402")
    end

    it "finds a township or New England town that is not a Census place" do
      expect(label("Montclair, NJ")).to eq("Montclair, NJ")
      expect(label("Lawrence Township, NJ")).to eq("Lawrence, NJ")
    end

    it "finds a city named in only one state without the state" do
      expect(label("Missoula")).to eq("Missoula, MT")
    end

    it "asks which one when a city is in more than one state" do
      result = described_class.locate("Springfield")
      expect(result).to be_a(CensusLocation::Ambiguous)
      expect(result.states).to eq(%w[IL MO])
    end

    it "finds nothing for a place it does not know, or a state that is not one" do
      expect(described_class.locate("Atlantis, OH")).to be_nil
      expect(described_class.locate("Dayton, Ohioo")).to be_nil
      expect(described_class.locate("99999")).to be_nil
      expect(described_class.locate("")).to be_nil
      expect(described_class.locate(nil)).to be_nil
    end
  end

  describe ".load_from_file!" do
    it "loads every row of the committed file" do
      expect(described_class.load_from_file!).to be > 90_000
      expect(described_class.find_by(kind: "place", state: "OH", name_key: "dayton")).to be_present
    end
  end
end
