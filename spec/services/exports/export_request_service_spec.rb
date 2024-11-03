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

  let!(:request_3t) do
    create(:request,
           :started,
           :with_item_requests,
           organization: org,
           request_items: [{ item_id: item_3t.id, quantity: 150 }])
  end

  let!(:request_2t) do
    create(:request,
           :fulfilled,
           :with_item_requests,
           organization: org,
           request_items: [{ item_id: item_2t.id, quantity: 100 }])
  end

  let!(:request_with_deleted_items) do
    request = create(:request,
           :fulfilled,
           :with_item_requests,
           organization: org,
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
           :with_item_requests,
           organization: org,
           request_items: [
             { item_id: item_4t.id, quantity: 77, request_unit: "" }
           ])
  end

  let!(:request_4t_pack) do
    create(:request,
           :started,
           :with_item_requests,
           organization: org,
           request_items: [
             { item_id: item_4t.id, quantity: 153, request_unit: "pack" }
           ])
  end

  subject do
    described_class.new(Request.all).generate_csv_data
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
          "Status",
          "2T Diapers",
          "3T Diapers",
          "4T Diapers",
          "4T Diapers - packs",
          "<DELETED_ITEMS>"
        ])
      end

      it "includes rows for each request" do
        expect(subject.count).to eq(7)
      end

      it "has expected data for the 3T Diapers request" do
        expect(subject[1]).to eq([
          request_3t.created_at.strftime("%m/%d/%Y").to_s,
          request_3t.partner.name,
          request_3t.status.humanize,
          0,   # 2T Diapers
          150, # 3T Diapers
          0,   # 4T Diapers
          0,   # 4T Diapers - pack
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the 2T Diapers request" do
        expect(subject[2]).to eq([
          request_2t.created_at.strftime("%m/%d/%Y").to_s,
          request_2t.partner.name,
          request_2t.status.humanize,
          100, # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          0,   # 4T Diapers - pack
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with deleted items" do
        expect(subject[3]).to eq([
          request_with_deleted_items.created_at.strftime("%m/%d/%Y").to_s,
          request_with_deleted_items.partner.name,
          request_with_deleted_items.status.humanize,
          0,   # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          0,   # 4T Diapers - pack
          400  # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with multiple items" do
        expect(subject[4]).to eq([
          request_with_multiple_items.created_at.strftime("%m/%d/%Y").to_s,
          request_with_multiple_items.partner.name,
          request_with_multiple_items.status.humanize,
          3,   # 2T Diapers
          2,   # 3T Diapers
          0,   # 4T Diapers
          4,   # 4T Diapers - pack
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with 4T diapers without pack unit" do
        expect(subject[5]).to eq([
          request_4t.created_at.strftime("%m/%d/%Y").to_s,
          request_4t.partner.name,
          request_4t.status.humanize,
          0,   # 2T Diapers
          0,   # 3T Diapers
          77,  # 4T Diapers
          0,   # 4T Diapers - pack
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with 4T diapers with pack unit" do
        expect(subject[6]).to eq([
          request_4t_pack.created_at.strftime("%m/%d/%Y").to_s,
          request_4t_pack.partner.name,
          request_4t_pack.status.humanize,
          0,   # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          153, # 4T Diapers - pack
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data even when the unit was deleted" do
        item_4t.request_units.destroy_all
        expect(subject[6]).to eq([
          request_4t_pack.created_at.strftime("%m/%d/%Y").to_s,
          request_4t_pack.partner.name,
          request_4t_pack.status.humanize,
          0,   # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          153, # 4T Diapers - pack
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
          "Status",
          "2T Diapers",
          "3T Diapers",
          "4T Diapers",
          "<DELETED_ITEMS>"
        ])
      end

      it "includes rows for each request" do
        expect(subject.count).to eq(7)
      end

      it "has expected data for the 3T Diapers request" do
        expect(subject[1]).to eq([
          request_3t.created_at.strftime("%m/%d/%Y").to_s,
          request_3t.partner.name,
          request_3t.status.humanize,
          0,   # 2T Diapers
          150, # 3T Diapers
          0,   # 4T Diapers
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the 2T Diapers request" do
        expect(subject[2]).to eq([
          request_2t.created_at.strftime("%m/%d/%Y").to_s,
          request_2t.partner.name,
          request_2t.status.humanize,
          100, # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with deleted items" do
        expect(subject[3]).to eq([
          request_with_deleted_items.created_at.strftime("%m/%d/%Y").to_s,
          request_with_deleted_items.partner.name,
          request_with_deleted_items.status.humanize,
          0,   # 2T Diapers
          0,   # 3T Diapers
          0,   # 4T Diapers
          400  # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with multiple items" do
        expect(subject[4]).to eq([
          request_with_multiple_items.created_at.strftime("%m/%d/%Y").to_s,
          request_with_multiple_items.partner.name,
          request_with_multiple_items.status.humanize,
          3,   # 2T Diapers
          2,   # 3T Diapers
          4,   # 4T Diapers
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with 4T diapers without pack unit" do
        expect(subject[5]).to eq([
          request_4t.created_at.strftime("%m/%d/%Y").to_s,
          request_4t.partner.name,
          request_4t.status.humanize,
          0,   # 2T Diapers
          0,   # 3T Diapers
          77,  # 4T Diapers
          0    # <DELETED_ITEMS>
        ])
      end

      it "has expected data for the request with 4T diapers with pack unit" do
        expect(subject[6]).to eq([
          request_4t_pack.created_at.strftime("%m/%d/%Y").to_s,
          request_4t_pack.partner.name,
          request_4t_pack.status.humanize,
          0,   # 2T Diapers
          0,   # 3T Diapers
          153, # 4T Diapers
          0    # <DELETED_ITEMS>
        ])
      end
    end
  end
end
