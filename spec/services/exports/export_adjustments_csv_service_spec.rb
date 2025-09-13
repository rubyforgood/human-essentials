RSpec.describe Exports::ExportAdjustmentsCSVService do
  # Create organization after items to ensure proper associations
  let!(:item1) { create(:item, name: "item1") }
  let!(:item2) { create(:item, name: "item2") }
  let!(:item3) { create(:item, name: "item3") }
  let!(:item4) { create(:item, name: "item4") }
  let!(:item5) { create(:item, :inactive, name: "item5") }

  # Now create organization and associate items with it
  let(:organization) do
    org = create(:organization)
    [item1, item2, item3, item4, item5].each do |item|
      item.update!(organization_id: org.id)
    end
    org
  end

  let(:sorted_item_names) do
    [item1, item2, item3, item4, item5].map(&:name).sort
  end

  let(:storage_location) { create(:storage_location, organization: organization, name: "Test Storage Location") }
  let(:user) { create(:user, organization: organization) }

  around do |example|
    travel_to Time.zone.local(2024, 12, 25)
    example.run
    travel_back
  end

  describe "#generate_csv_data" do
    subject { described_class.generate_csv(adjustments, organization) }

    context "with multiple adjustments and items" do
      let(:adjustments) do
        [
          # 1st adjustment with 2 items
          create(:adjustment,
            user_id: user.id,
            storage_location: storage_location,
            organization: organization,
            comment: "adjustment 1",
            line_items_attributes: [
              {item_id: item1.id, quantity: 10},
              {item_id: item2.id, quantity: -5}
            ]),

          # 2nd adjustment with 1 item
          create(:adjustment,
            user_id: user.id,
            storage_location: storage_location,
            organization: organization,
            comment: "adjustment 2",
            line_items_attributes: [
              {item_id: item3.id, quantity: 3}
            ]),

          # 3rd adjustment with the :with_items trait
          create(:adjustment, :with_items,
            user_id: user.id,
            storage_location: storage_location,
            organization: organization,
            comment: "adjustment 3",
            item: item1,
            item_quantity: 7)
        ]
      end

      it "should include the correct adjustment data" do
        csv = <<~CSV
          Created date,Storage Area,Comment,Change Diff #,item1,item2,item3,item4,item5
          2024-12-25,Test Storage Location,adjustment 1,2,10,-5,0,0,0
          2024-12-25,Test Storage Location,adjustment 2,1,0,0,3,0,0
          2024-12-25,Test Storage Location,adjustment 3,1,7,0,0,0,0
        CSV

        expect(subject).to eq(csv)
      end
    end

    context "when there are no adjustments" do
      let(:adjustments) { [] }

      it "returns only headers row" do
        csv = <<~CSV
          Created date,Storage Area,Comment,Updates,item1,item2,item3,item4,item5
        CSV

        expect(subject).to eq(csv)
      end
    end
  end
end
