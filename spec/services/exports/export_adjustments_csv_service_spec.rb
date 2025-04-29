RSpec.describe Exports::ExportAdjustmentsCSVService, :wip do
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

  let(:expected_headers) do
    [
      "Created date", "Storage Area",
      "Comment", "# of changes"
    ] + sorted_item_names
  end

  let(:storage_location) { create(:storage_location, organization: organization) }
  let(:user) { create(:user, organization: organization) }

  describe "#generate_csv_data" do
    subject { described_class.new(adjustments: adjustments, organization: organization).generate_csv_data }

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

      it "should have the expected headers" do
        expect(subject[0]).to eq(expected_headers)
      end

      it "should include the adjustment data in the rows" do
        # Check 1st adjustment
        expect(subject[1]).to include(
          adjustments[0].created_at.strftime("%F"),
          storage_location.name,
          "adjustment 1",
          2  # Number of items changed
        )

        # Check 2nd adjustment
        expect(subject[2]).to include(
          adjustments[1].created_at.strftime("%F"),
          storage_location.name,
          "adjustment 2",
          1  # Number of items changed
        )

        # Check 3rd adjustment
        expect(subject[3]).to include(
          adjustments[2].created_at.strftime("%F"),
          storage_location.name,
          "adjustment 3",
          1  # Number of items changed
        )
      end

      it "should include the correct item quantities" do
        # Get indexes of item quantity columns
        item1_idx = expected_headers.index(item1.name)
        item2_idx = expected_headers.index(item2.name)
        item3_idx = expected_headers.index(item3.name)
        item4_idx = expected_headers.index(item4.name)
        item5_idx = expected_headers.index(item5.name)

        # Check 1st adjustment
        expect(subject[1][item1_idx]).to eq(10)
        expect(subject[1][item2_idx]).to eq(-5)
        expect(subject[1][item3_idx]).to eq(0)
        expect(subject[1][item4_idx]).to eq(0)
        expect(subject[1][item5_idx]).to eq(0)

        # Check 2nd adjustment
        expect(subject[2][item1_idx]).to eq(0)
        expect(subject[2][item2_idx]).to eq(0)
        expect(subject[2][item3_idx]).to eq(3)
        expect(subject[2][item4_idx]).to eq(0)
        expect(subject[2][item5_idx]).to eq(0)

        # Check 3rd adjustment
        expect(subject[3][item1_idx]).to eq(7)
        expect(subject[3][item2_idx]).to eq(0)
        expect(subject[3][item3_idx]).to eq(0)
        expect(subject[3][item4_idx]).to eq(0)
        expect(subject[3][item5_idx]).to eq(0)
      end

      it "should correctly sum up the number of changes" do
        idx = expected_headers.index("# of changes")
        expect(subject[1][idx]).to eq(2)
        expect(subject[2][idx]).to eq(1)
        expect(subject[3][idx]).to eq(1)
      end
    end

    context "when there are no adjustments" do
      let(:adjustments) { [] }

      it "returns only headers row" do
        expect(subject.size).to eq(1)
        expect(subject[0]).to eq(expected_headers)
      end
    end
  end

  describe "#generate_csv" do
    subject { described_class.new(adjustments: adjustments, organization: organization).generate_csv }

    let(:adjustments) do
      [
        create(:adjustment,
          storage_location: storage_location,
          organization: organization,
          line_items_attributes: [
            {item_id: item1.id, quantity: 111},
            {item_id: item2.id, quantity: -7}
          ])
      ]
    end

    it "generates valid CSV data" do
      expect(subject).to be_a(String)
      parsed_csv = CSV.parse(subject, headers: true)
      expect(parsed_csv.headers).to include("Created date",
        "Storage Area",
        "Comment",
        "# of changes",
        item1.name,
        item2.name,
        item3.name,
        item4.name)

      expect(parsed_csv.first["# of changes"]).to eq("2")
      expect(parsed_csv.first[item1.name]).to eq("111")
      expect(parsed_csv.first[item2.name]).to eq("-7")
    end
  end
end
