# avoid Rubocop failing with an infinite loop when it checks this cop
# rubocop:disable Layout/ArrayAlignment
describe DistributionPdf do
  let(:distribution) { FactoryBot.create(:distribution) }
  let(:item1) { FactoryBot.create(:item, name: "Item 1", package_size: 50, value_in_cents: 100) }
  let(:item2) { FactoryBot.create(:item, name: "Item 2", value_in_cents: 200) }
  let(:item3) { FactoryBot.create(:item, name: "Item 3", value_in_cents: 300) }
  let(:item4) { FactoryBot.create(:item, name: "Item 4", package_size: 25, value_in_cents: 400) }
  before(:each) do
    FactoryBot.create(:line_item, itemizable: distribution, item: item1, quantity: 50)
    FactoryBot.create(:line_item, itemizable: distribution, item: item2, quantity: 100)
    FactoryBot.create(:request, distribution: distribution,
      request_items: [{"item_id" => item2.id, "quantity" => 30},
        {"item_id" => item3.id, "quantity" => 50}, {"item_id" => item4.id, "quantity" => 120}])
  end

  specify "#request_data" do
    results = described_class.new(@organization, distribution).request_data
    expect(results).to eq([
                            ["Items Received", "Requested", "Received", "Value/item", "In-Kind Value Received", "Packages"],
      ["Item 1", "", 50, "$1.00", "$50.00", "1"],
      ["Item 2", 30, 100, "$2.00", "$200.00", nil],
      ["Item 3", 50, "", "$3.00", nil, nil],
      ["Item 4", 120, "", "$4.00", nil, nil],
      ["", "", "", "", ""],
      ["Total Items Received", 200, 150, "", "$250.00", ""]
                          ])
  end

  specify "#non_request_data" do
    results = described_class.new(@organization, distribution).non_request_data
    expect(results).to eq([
                            ["Items Received", "Value/item", "In-Kind Value", "Quantity", "Packages"],
      ["Item 1", "$1.00", "$50.00", 50, "1"],
      ["Item 2", "$2.00", "$200.00", 100, nil],
      ["", "", "", "", ""],
      ["Total Items Received", "", "$250.00", 150, ""]
                          ])
  end
end
# rubocop:enable Layout/ArrayAlignment
