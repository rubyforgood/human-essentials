RSpec.describe Replenishment::LocationBreakdown do
  let(:organization) { create(:organization) }
  let(:partner) { create(:partner, organization:) }
  let(:main) { create(:storage_location, organization:, name: "Main Office") }
  let(:shack) { create(:storage_location, organization:, name: "Storage Shack") }
  let(:empty) { create(:storage_location, organization:, name: "Empty Room") }
  let(:diapers) { create(:item, organization:, name: "Size 1 Diapers") }
  let(:today) { Date.new(2026, 9, 15) }

  def distribute(location, quantity, issued_at)
    distribution = create(:distribution, organization:, storage_location: location, partner:, issued_at:)
    distribution.line_items.create!(item: diapers, quantity:)
  end

  before do
    empty
    3.times do |i|
      month = today.beginning_of_month.months_ago(i + 1) + 2.days
      distribute(main, 300, month)
      distribute(shack, 30, month)
    end
    distribute(main, 9999, today.beginning_of_month + 1.day) # current month is ignored
    TestInventory.create_inventory(organization, {main.id => {diapers.id => 150}, shack.id => {diapers.id => 900}})
  end

  subject(:rows) { described_class.new(organization, diapers, today:).rows }

  it "gives each location its own stock and recent demand" do
    by_name = rows.index_by { |r| r.storage_location.name }
    expect(by_name["Main Office"]).to have_attributes(on_hand: 150, monthly_demand: 300.0)
    expect(by_name["Storage Shack"]).to have_attributes(on_hand: 900, monthly_demand: 30.0)
  end

  it "puts the location that will run out first at the top" do
    expect(rows.first.storage_location.name).to eq("Main Office")
    expect(rows.first.days_of_supply).to eq(15)
  end

  it "skips locations with no stock and no demand" do
    expect(rows.map { |r| r.storage_location.name }).not_to include("Empty Room")
  end
end
