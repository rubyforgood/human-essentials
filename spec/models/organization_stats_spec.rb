# == No Schema Information
#
RSpec.describe OrganizationStats, type: :model do
  let(:partners) { [] }
  let(:storage_locations) { [] }
  let(:donation_sites) { [] }
  let(:current_org) do
    double("org", partners: partners, storage_locations: storage_locations, donation_sites: donation_sites)
  end

  subject { described_class.new(current_org) }

  describe "partners_added method >" do
    context "current org is nil >" do
      let(:current_org) { nil }

      it "should return 0" do
        expect(subject.partners_added).to eq(0)
      end
    end

    context "current org is not nil >" do
      let(:partners) { %w(element1 element2) }

      it "should return actual count of partners" do
        expect(subject.partners_added).to eq(2)
      end
    end
  end

  describe "storage_locations_added method >" do
    context "current org is nil >" do
      let(:current_org) { nil }

      it "should return 0" do
        expect(subject.storage_locations_added).to eq(0)
      end
    end

    context "current org is not nil >" do
      let(:storage_locations) { %w(loc1 loc2 loc3) }

      it "should return actual count of locations" do
        expect(subject.storage_locations_added).to eq(3)
      end
    end
  end

  describe "donation_sites_added method >" do
    context "current org is nil >" do
      let(:current_org) { nil }

      it "should return 0" do
        expect(subject.donation_sites_added).to eq(0)
      end
    end

    context "current org is not nil >" do
      let(:donation_sites) { %w(site1 site2 site3) }

      it "should return actual count of donation sites" do
        expect(subject.donation_sites_added).to eq(3)
      end
    end
  end

  describe "locations_with_inventory method >" do
    context "current org is nil >" do
      let(:current_org) { nil }

      it "should return an empty array" do
        expect(subject.locations_with_inventory).to eq([])
      end
    end

    context "current org is not nil + locations have items >" do
      let(:storage_location_1) { create :storage_location, :with_items }
      let(:storage_locations) { [storage_location_1] }

      it "should return storage location" do
        expect(subject.locations_with_inventory).to include(storage_location_1)
      end
    end

    context "current org is not nil + no locations have items >" do
      let(:storage_location_1) { create :storage_location }
      let(:storage_locations) { [storage_location_1] }

      it "should return an empty array" do
        expect(subject.locations_with_inventory).to eq([])
      end
    end
  end
end
