RSpec.describe NearbyBanksQuery do
  let(:dayton) { CensusLocation::Point.new(label: "Dayton, OH", latitude: 39.784743, longitude: -84.199632) }

  it "returns located banks closest first, with the distance in miles" do
    create(:bank_listing, name: "Cincinnati", latitude: 39.140183, longitude: -84.505829)
    create(:bank_listing, name: "Dayton", latitude: 39.784743, longitude: -84.199632)
    create(:bank_listing, name: "Xenia", latitude: 39.683133, longitude: -83.940808)
    create(:bank_listing, name: "Unplaced", latitude: nil, longitude: nil)

    results = described_class.call(dayton)

    expect(results.map { |r| r.listing.name }).to eq(%w[Dayton Xenia Cincinnati])
    expect(results.first.miles).to eq(0)
    # Measured against the great-circle distance Dayton to Cincinnati: 47.6 miles.
    expect(results.last.miles).to be_within(0.5).of(47.6)
  end

  it "returns at most the limit" do
    create_list(:bank_listing, 10)
    expect(described_class.call(dayton).size).to eq(NearbyBanksQuery::LIMIT)
  end
end
