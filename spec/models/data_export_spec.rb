# == No Schema Information
#

RSpec.describe DataExport, type: :model do
  let(:org) { create(:organization) }
  let(:type) { "Donation" }
  let(:filters) { {} }

  subject { described_class.new(org, type, filters, nil) }

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

      before do
        allow_any_instance_of(Partner).to receive(:contact_person) { Hash.new }
      end

      it "should return a CSV string with partner data" do
        expect(subject.as_csv).to include(partner.email)
      end
    end

    context "type is Distribution >" do
      let(:type) { "Distribution" }
      let(:partner_name) { "Cool Beans" }
      let(:partner) { create(:partner, name: partner_name, organization: org) }
      let!(:distribution_1) { create(:distribution, partner: partner, organization: org, issued_at: 11.days.ago) }
      let(:item) { create(:item) }
      let!(:distribution_2) { create(:distribution, :with_items, partner: partner, item: item, organization: org, issued_at: 3.days.ago) }

      it "should return a CSV string with distribution data" do
        expect(subject.as_csv).to include(partner_name)
        expect(subject.as_csv).to include(distribution_1.issued_at.strftime("%F"))
        expect(subject.as_csv.split("\n").size).to eql(3)
      end

      it "filters by the given filter" do
        filters.merge!(by_item_id: item.id)

        expect(subject.as_csv).to include(partner_name)
        expect(subject.as_csv.split("\n").size).to eql(2)
      end

      it "filters by the given date range" do
        export = DataExport.new(org, type, {}, 10.days.ago..Time.zone.today)

        expect(export.as_csv).to include(partner_name)
        expect(export.as_csv.split("\n").size).to eql(2)
        expect(subject.as_csv).to include(distribution_2.issued_at.strftime("%F"))
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

    context "type is Request >" do
      let(:type) { "Request" }
      let(:item) { create :item, name: "3T Diapers" }
      let!(:request) do
        create(:request,
               :started,
               organization: org,
               request_items: [{ item_id: item.id, quantity: 150 }])
      end

      it "should return a CSV string with request and item data" do
        expect(subject.as_csv).to include("Date,Requestor,Status")
        expect(subject.as_csv).to include(request.created_at.strftime("%m/%d/%Y").to_s)
        expect(subject.as_csv).to include(item.name)
        expect(subject.as_csv).to include("150")
      end
    end

    context "type is PartnerDistribution >" do
      let(:type) { "PartnerDistribution" }
      let!(:distribution) { create :distribution, :with_items, organization: org }
      let(:filters) { { partner_id: distribution.partner_id } }

      subject { described_class.new(org, type, filters, nil) }

      it "should return a CSV string with distribution and line item data" do
        expect(subject.as_csv).to include("Date,Source Inventory,Total Items")
        expect(subject.as_csv).to include(distribution.issued_at.strftime("%m/%d/%Y").to_s)
        expect(subject.as_csv).to include(distribution.storage_location.name)
        expect(subject.as_csv).to include(distribution.line_items.first.item.name)
        expect(subject.as_csv).to include("100")
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
