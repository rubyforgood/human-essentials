RSpec.describe BankListingImportService do
  let(:sample) { BankListingImportService::SAMPLE_FETCH }

  before { create_census_locations }

  it "imports both directories as one list, merging a bank that is in both" do
    result = described_class.call(fetch: sample)

    expect(result).to be_success
    expect(result.imported).to eq(7)
    expect(result.unplaced).to be_empty

    pawnee = BankListing.find_by!(name: "Pawnee Diaper Bank")
    expect(pawnee).to have_attributes(city: "Dayton", state: "OH", diapers: true, period_supplies: true, ndbn_member_id: 90001)
    expect(pawnee.latitude).to be_within(0.001).of(39.784743)
  end

  it "reads both of the period supply directory's field layouts, and skips a point with no city" do
    described_class.call(fetch: sample)

    expect(BankListing.find_by!(name: "Sweetums Period Project")).to have_attributes(city: "Xenia", state: "OH", diapers: false, period_supplies: true)
    expect(BankListing.find_by(name: "No City Given")).to be_nil
  end

  it "corrects a misspelled city, and places a village the Census does not name at the nearest town it does" do
    described_class.call(fetch: sample)

    expect(BankListing.find_by!(name: "Central Worcester Diaper Bank").city).to eq("Worcester")
    expect(BankListing.find_by!(name: "Winston-Salem Period Pantry").city).to eq("Winston-Salem")
    hyannis = BankListing.find_by!(name: "Cape Cod Baby Center")
    expect(hyannis.city).to eq("Hyannis")
    expect(hyannis.latitude).to be_within(0.001).of(41.661478)
  end

  it "reports a bank it cannot place, and keeps it without a location" do
    CensusLocation.where(name_key: "helena").delete_all
    result = described_class.call(fetch: sample)

    expect(result.unplaced).to eq(["Big Sky Diaper Bank (Helena, MT)"])
    expect(BankListing.find_by!(name: "Big Sky Diaper Bank").latitude).to be_nil
  end

  it "removes a bank that has left the directories" do
    create(:bank_listing, name: "Gone Diaper Bank")
    described_class.call(fetch: sample)

    expect(BankListing.find_by(name: "Gone Diaper Bank")).to be_nil
  end

  context "when it should keep last week's list" do
    before { described_class.call(fetch: sample) }

    it "keeps it when a directory will not download" do
      failing = ->(url) { (url == BankListingImportService::SOURCES[:period_supplies]) ? raise(SocketError, "getaddrinfo") : sample.call(url) }
      result = described_class.call(fetch: failing)

      expect(result).not_to be_success
      expect(result.error).to include("Could not download the period supplies directory", "getaddrinfo")
      expect(BankListing.count).to eq(7)
    end

    # The sample NDBN directory has five banks.
    def without_placemarks(count)
      ->(url) {
        kml = sample.call(url)
        next kml unless url == BankListingImportService::SOURCES[:diapers]
        count.times { kml = kml.sub(%r{<Placemark>.*?</Placemark>}m, "") }
        kml
      }
    end

    it "keeps it when a directory comes back with less than half the banks" do
      result = described_class.call(fetch: without_placemarks(3))

      expect(result.error).to eq("The diapers directory has 2 banks, down from 5. " \
        "Kept last week's list in case the map has moved or been emptied.")
      expect(BankListing.count).to eq(7)
    end

    it "keeps it when a directory comes back empty" do
      result = described_class.call(fetch: without_placemarks(5))

      expect(result.error).to eq("The diapers directory had no banks in it.")
      expect(BankListing.count).to eq(7)
    end

    it "takes a smaller list that is still at least half" do
      result = described_class.call(fetch: without_placemarks(2))

      expect(result).to be_success
      expect(BankListing.where(diapers: true).count).to eq(3)
    end
  end
end
