RSpec.describe BankMapQuery do
  describe BankMapQuery::AlbersUsa do
    # The outline in static/_bank_map was drawn by d3-geo's geoAlbersUsa().scale(1280)
    # .translate([480, 300]). These are the points d3 gave for the same coordinates, to a tenth
    # of a unit. If one moves, the lights no longer sit on their cities.
    {
      "Dayton, OH" => [39.7797, -84.1998, 690.6, 263.2],
      "Portland, OR" => [45.5371, -122.65, 78.7, 88.2],
      "Anchorage, AK" => [61.17425, -149.284329, 112.9, 535.8],
      "Honolulu, HI" => [21.324347, -157.84764, 263.1, 540.0]
    }.each do |place, (latitude, longitude, x, y)|
      it "puts #{place} where d3 does" do
        expect(described_class.point(latitude, longitude).map { |v| v.round(1) }).to eq([x, y])
      end
    end

    it "has nowhere to put a place outside the fifty states" do
      expect(described_class.point(18.412076, -65.979806)).to be_nil # Carolina, Puerto Rico
      expect(described_class.point(13.4745, 144.7504)).to be_nil # Hagåtña, Guam
    end
  end

  describe ".call" do
    it "returns a light for each located listing, east to west" do
      create(:bank_listing, name: "Portland", state: "OR", latitude: 45.5371, longitude: -122.65)
      create(:bank_listing, name: "Dayton", state: "OH", latitude: 39.7797, longitude: -84.1998)
      create(:bank_listing, name: "Honolulu", state: "HI", latitude: 21.324347, longitude: -157.84764)
      create(:bank_listing, name: "Unplaced", latitude: nil, longitude: nil)

      map = described_class.call

      expect(map.count).to eq(3)
      expect(map.lights.map { |light| [light.x, light.y] }).to eq([[690.6, 263.2], [263.1, 540.0], [78.7, 88.2]])
      expect(map.puerto_rico).to be(false)
    end

    it "colours a light by what the bank gives out" do
      create(:bank_listing, diapers: true, period_supplies: false, longitude: -84)
      create(:bank_listing, diapers: false, period_supplies: true, longitude: -90)
      create(:bank_listing, diapers: true, period_supplies: true, longitude: -100)

      expect(described_class.call.lights.map(&:kind)).to eq(%w[d p b])
    end

    it "gives Puerto Rico's banks a spot of their own, side by side" do
      create_list(:bank_listing, 2, city: "Carolina", state: "PR", latitude: 18.412076, longitude: -65.979806)

      map = described_class.call

      expect(map.puerto_rico).to be(true)
      expect(map.lights.map(&:y).uniq).to eq([BankMapQuery::PUERTO_RICO[1]])
      expect(map.lights.map(&:x)).to eq([904.5, 895.5])
    end

    it "leaves out a listing whose coordinates are on no part of the map" do
      create(:bank_listing, city: "Hagåtña", state: "GU", latitude: 13.4745, longitude: 144.7504)

      expect(described_class.call.count).to eq(0)
    end

    it "says when the listings were last imported" do
      create(:bank_listing, updated_at: Time.zone.local(2026, 10, 12))
      create(:bank_listing, updated_at: Time.zone.local(2026, 10, 19))

      expect(described_class.call.as_of).to eq(Time.zone.local(2026, 10, 19))
    end

    it "is empty, not an error, before anything has been imported" do
      map = described_class.call

      expect(map.any?).to be(false)
      expect(map.as_of).to be_nil
    end
  end
end
