# == No Schema Information
#

RSpec.describe DataExport, type: :model do
  let(:org) { create(:organization) }
  let(:type) { "Donation" }

  subject { described_class.new(org, type) }

  describe "as_csv" do
    context "current org is nil >" do
      let(:org) { nil }

      it "should return nil" do
        expect(subject.as_csv).to be_nil
      end
    end

    context "type is nil >" do
      let(:type) { nil }

      it "should return nil" do
        expect(subject.as_csv).to be_nil
      end
    end

    context "type is not recognized >" do
      let(:type) { "unknown" }

      it "should return nil" do
        expect(subject.as_csv).to be_nil
      end
    end

    context "type is Donation >" do
      let!(:donation) { create(:donation, organization: org) }

      it "should return a CSV string with donation data" do
        expect(subject.as_csv).to include(donation.source_view)
      end
    end

    context "type is DonationSite >" do
      let(:type) { "DonationSite" }
      let!(:donation_site) { create(:donation_site, organization: org) }

      it "should return a CSV string with donation site data" do
        expect(subject.as_csv).to include(donation_site.name)
      end
    end

    context "type is Purchase >" do
      let(:type) { "Purchase" }
      let!(:purchase) { create(:purchase, organization: org) }

      it "should return a CSV string with donation site data" do
        expect(subject.as_csv).to include(purchase.purchased_from)
      end
    end

    context "type is Partner >" do
      let(:type) { "Partner" }
      let!(:partner) { create(:partner, organization: org) }

      it "should return a CSV string with partner data" do
        expect(subject.as_csv).to include(partner.email)
      end
    end

    context "type is Distribution >" do
      let(:type) { "Distribution" }
      let(:partner_name) { "Cool Beans" }
      let(:partner) { create(:partner, name: partner_name, organization: org) }
      let!(:distribution) { create(:distribution, partner: partner, organization: org) }

      it "should return a CSV string with distribution data" do
        expect(subject.as_csv).to include(partner_name)
        expect(subject.as_csv).to include(distribution.issued_at.strftime("%F"))
      end
    end

    context "type is DiaperDriveParticipant >" do
      let(:type) { "DiaperDriveParticipant" }
      let!(:participant) { create(:diaper_drive_participant, organization: org) }

      it "should return a CSV string with diaper drive participant data" do
        expect(subject.as_csv).to include(participant.business_name)
      end
    end

    context "type is Vendor >" do
      let(:type) { "Vendor" }
      let!(:participant) { create(:vendor, organization: org) }

      it "should return a CSV string with Vendor data" do
        expect(subject.as_csv).to include(participant.business_name)
      end
    end

    context "type is StorageLocation >" do
      let(:type) { "StorageLocation" }
      let!(:location) { create(:storage_location, organization: org) }

      it "should return a CSV string with location data" do
        expect(subject.as_csv).to include(location.address)
      end
    end

    context "type is Adjustment >" do
      let(:type) { "Adjustment" }
      let(:location_name) { "Location A" }
      let(:storage_location) { create(:storage_location, name: location_name, organization: org) }
      let!(:adjustment) { create(:adjustment, storage_location: storage_location, organization: org) }

      it "should return a CSV string with adjustment data" do
        expect(subject.as_csv).to include(location_name)
        expect(subject.as_csv).to include(adjustment.comment)
      end
    end

    context "type is Transfer >" do
      let(:type) { "Transfer" }
      let(:comment) { "This is a comment" }
      let!(:transfer) { create(:transfer, comment: comment, organization: org) }

      it "should return a CSV string with transfer data" do
        expect(subject.as_csv).to include(comment)
      end
    end

    context "type is Item >" do
      let(:type) { "Item" }
      let!(:item) { create(:item, organization: org) }
    end

    context "type is BarcodeItem >" do
      let(:type) { "BarcodeItem" }
      let!(:global_item) { create(:global_barcode_item, quantity: 10, organization: org) }
      let!(:item) { create(:barcode_item, quantity: 11, organization: org) }

      it "should return a CSV string with barcode item data" do
        expect(subject.as_csv).not_to include("true")
        expect(subject.as_csv).to include("11")
      end
    end
  end

  describe 'SUPPORTED_TYPES' do
    specify 'the array cannot be modified' do
      expect(-> { DataExport::SUPPORTED_TYPES << 'foo' }).to raise_error(FrozenError)
    end

    specify 'elements in the array cannot be modified' do
      DataExport::SUPPORTED_TYPES.each do |frozen_string|
        expect(-> { frozen_string << 'foo' }).to raise_error(FrozenError)
      end
    end
  end
end
