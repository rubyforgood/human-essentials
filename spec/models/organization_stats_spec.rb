# == No Schema Information
#
RSpec.describe OrganizationStats, type: :model do
  let(:current_org) { create(:organization) }
  let(:inventory) { View::Inventory.new(current_org.id) }

  subject { described_class.new(current_org, inventory) }

  describe "partners_added method >" do
    context "current org is nil >" do
      let(:current_org) { nil }
      let(:inventory) { nil }

      it "should return 0" do
        expect(subject.partners_added).to eq(0)
      end
    end

    context "current org is not nil >" do
      before(:each) do
        FactoryBot.create_list(:partner, 2, organization: current_org)
      end

      it "should return actual count of partners" do
        expect(subject.partners_added).to eq(2)
      end
    end
  end

  describe "storage_locations_added method >" do
    context "current org is nil >" do
      let(:current_org) { nil }
      let(:inventory) { nil }

      it "should return 0" do
        expect(subject.storage_locations_added).to eq(0)
      end
    end

    context "current org is not nil >" do
      before(:each) do
        create_list(:storage_location, 3, organization: current_org)
      end

      it "should return actual count of locations" do
        expect(subject.storage_locations_added).to eq(3)
      end
    end
  end

  describe "donation_sites_added method >" do
    context "current org is nil >" do
      let(:current_org) { nil }
      let(:inventory) { nil }

      it "should return 0" do
        expect(subject.donation_sites_added).to eq(0)
      end
    end

    context "current org is not nil >" do
      before(:each) do
        create_list(:donation_site, 3, organization: current_org)
      end

      it "should return actual count of donation sites" do
        expect(subject.donation_sites_added).to eq(3)
      end
    end
  end

  describe "num_locations_with_inventory method >" do
    context "current org is nil >" do
      let(:current_org) { nil }
      let(:inventory) { nil }

      it "should return an empty array" do
        expect(subject.num_locations_with_inventory).to eq(0)
      end
    end

    context "current org is not nil + locations have items >" do
      let(:storage_location_1) { create :storage_location }
      let(:item) { create(:item, organization: current_org) }
      let(:storage_locations) { [storage_location_1] }
      before(:each) do
        TestInventory.create_inventory(current_org, {
          storage_location_1.id => {
            item.id => 50
          }
        })
      end

      it "should return storage location" do
        expect(subject.num_locations_with_inventory).to eq(1)
      end
    end

    context "current org is not nil + no locations have items >" do
      let(:storage_location_1) { create :storage_location }
      let(:storage_locations) { [storage_location_1] }

      it "should return an empty array" do
        expect(subject.num_locations_with_inventory).to eq(0)
      end
    end
  end
end
