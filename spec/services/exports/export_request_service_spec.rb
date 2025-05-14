RSpec.describe Exports::ExportRequestService do
  let(:org) { create(:organization) }

  let(:item_2t) { create :item, name: "2T Diapers" }
  let(:item_3t) { create :item, name: "3T Diapers" }
  let(:item_4t) do
    create :item, name: "4T Diapers" do |item|
      create(:item_unit, item: item, name: "pack")
    end
  end

  let(:item_deleted1) { create :item, :inactive, name: "Inactive Diapers1" }
  let(:item_deleted2) { create :item, :inactive, name: "Inactive Diapers2" }
  let!(:unrequested_item) { create :item, name: "Unrequested Item", organization: org }
  let!(:inactive_item) { create :item, name: "Inactive Item", active: false, organization: org }

  # Added to ensure sorting is working correctly, otherwise is duplicate behavior
  let!(:apple_item) { create :item, name: "apple", organization: org }
  let!(:banana_item) { create :item, name: "Banana", organization: org }
  let!(:zebra_item) { create :item, name: "Zebra", organization: org }

  let!(:partner) { create :partner, organization: org, name: "Howdy Partner" }

  let!(:inactive_item_request) do
    create(:request,
           :started,
           :child,
           :with_item_requests, 
           organization: org,
           partner: partner,
           request_items: [{ item_id: inactive_item.id, quantity: 777 }])
  end

  let!(:request_3t) do
    create(:request,
           :started,
           :child,
           :with_item_requests,
           organization: org,
           partner: partner,
           request_items: [{ item_id: item_3t.id, quantity: 150 }])
  end

  let!(:request_2t) do
    create(:request,
           :fulfilled,
           :individual,
           :with_item_requests,
           organization: org,
           partner: partner,
           request_items: [{ item_id: item_2t.id, quantity: 100 }])
  end

  let!(:request_with_deleted_items) do
    request = create(:request,
           :fulfilled,
           :with_item_requests,
           organization: org,
           partner: partner,
           request_items: [{ item_id: item_deleted1.id, quantity: 200 }, { item_id: item_deleted2.id, quantity: 200 }])
    item_deleted1.delete
    item_deleted2.delete
    request.reload
  end

  let!(:request_with_multiple_items) do
    create(
      :request,
      :started,
      :with_item_requests,
      organization: org,
      partner: partner,
      request_items: [
        {item_id: item_3t.id, quantity: 2},
        {item_id: item_2t.id, quantity: 3},
        {item_id: item_4t.id, quantity: 4, request_unit: "pack"}
      ]
    )
  end

  let!(:request_4t) do
    create(:request,
           :started,
           :quantity,
           :with_item_requests,
           organization: org,
           partner: partner,
           request_items: [
             { item_id: item_4t.id, quantity: 77, request_unit: "" }
           ])
  end

  let!(:request_4t_pack) do
    create(:request,
           :started,
           :quantity,
           :with_item_requests,
           organization: org,
           partner: partner,
           request_items: [
             { item_id: item_4t.id, quantity: 1, request_unit: "pack" }
           ])
  end

  # Update item name after the request has been created to ensure export shows
  # current item name.
  before do
    item_2t.update!(name: "2T Diapers -- UPDATED")
  end

  subject do
    described_class.new(Request.all, organization: org).generate_csv_data
  end

  context "with custom units feature enabled" do
    before do
      Flipper.enable(:enable_packs)
    end

    describe ".generate_csv_data" do
      it "includes headers as the first row with ordered item names alphabetically with deleted item included at the end" do
        expect(subject.first).to eq([
          "Date",
          "Requestor",
          "Type",
          "Status",
          "2T Diapers -- UPDATED",
          "3T Diapers",
          "4T Diapers",
          "4T Diapers - packs",
          "apple",
          "Banana",
          "Inactive Item",
          "Unrequested Item",
          "Zebra",
          "<DELETED_ITEMS>"
        ])
      end

      it "includes rows for each request" do
        expect(subject.count).to eq(8)
      end

      it "has expected data for the 3T Diapers request" do
        expect(subject).to include([
          request_3t.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Child",
          "Started",
          0,   # 2T Diapers
          150, # 3T Diapers
          0,   # 4T Diapers
          0,   # 4T Diapers - packs
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the 2T Diapers request" do
        expect(subject).to include([
          request_2t.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Individual",
          "Fulfilled",
          100, # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          0,   # 4T Diapers - packs
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with deleted items" do
        expect(subject).to include([
          request_with_deleted_items.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          nil,
          "Fulfilled",
          0,   # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          0,   # 4T Diapers - packs
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          400  # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with multiple items" do
        expect(subject).to include([
          request_with_multiple_items.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          nil,
          "Started",
          3,   # 2T Diapers
          2,   # 3T Diapers
          0,   # 4T Diapers
          4,   # 4T Diapers - packs
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with 4T diapers without pack unit" do
        expect(subject).to include([
          request_4t.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Quantity",
          "Started",
          0,   # 2T Diapers
          0,   # 3T Diapers
          77,  # 4T Diapers
          0,   # 4T Diapers - packs
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with 4T diapers with pack unit" do
        expect(subject).to include([
          request_4t_pack.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Quantity",
          "Started",
          0,   # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          1,   # 4T Diapers - packs
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data even when the unit was deleted" do
        item_4t.request_units.destroy_all
        expect(subject).to include([
          request_4t_pack.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Quantity",
          "Started",
          0,   # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          1, # 4T Diapers - packs
          0, # apple
          0, # Banana
          0, # Inactive Item
          0, # Unrequested Item
          0, # Zebra
          0    # <DELETED_ITEMS>
        ])
      end
    end
  end

  context "with custom units feature disabled" do
    before do
      Flipper.disable(:enable_packs)
    end

    describe ".generate_csv_data" do
      it "includes headers as the first row with ordered item names alphabetically with deleted item included at the end" do
        expect(subject.first).to eq([
          "Date",
          "Requestor",
          "Type",
          "Status",
          "2T Diapers -- UPDATED",
          "3T Diapers",
          "4T Diapers",
          "apple",
          "Banana",
          "Inactive Item",
          "Unrequested Item",
          "Zebra",
          "<DELETED_ITEMS>"
        ])
      end

      it "includes rows for each request" do
        expect(subject.count).to eq(8)
      end

      it "has expected data for the 3T Diapers request" do
        expect(subject).to include([
          request_3t.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Child",
          request_3t.status.humanize,
          0,   # 2T Diapers
          150, # 3T Diapers
          0,   # 4T Diapers
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the 2T Diapers request" do
        expect(subject).to include([
          request_2t.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Individual",
          "Fulfilled",
          100, # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with deleted items" do
        expect(subject).to include([
          request_with_deleted_items.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          nil,
          "Fulfilled",
          0,   # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          400  # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with multiple items" do
        expect(subject).to include([
          request_with_multiple_items.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          nil,
          "Started",
          3,   # 2T Diapers
          2,   # 3T Diapers
          4,   # 4T Diapers
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with 4T diapers without pack unit" do
        expect(subject).to include([
          request_4t.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Quantity",
          "Started",
          0,   # 2T Diapers
          0,   # 3T Diapers
          77,  # 4T Diapers
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with 4T diapers with pack unit" do
        expect(subject).to include([
          request_4t_pack.created_at.strftime("%m/%d/%Y").to_s,
          "Howdy Partner",
          "Quantity",
          "Started",
          0,   # 2T Diapers
          0,   # 3T Diapers
          1,   # 4T Diapers
          0,   # apple
          0,   # Banana
          0,   # Inactive Item
          0,   # Unrequested Item
          0,   # Zebra
          0    # <DELETED_ITEMS>
        ])
      end
    end
  end
end
