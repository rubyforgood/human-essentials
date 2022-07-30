# frozen_string_literal: true

RSpec.describe DonationItemizedBreakdownService, type: :service, skip_seed: true do
  let(:organization) { create(:organization) }
  let(:donation_ids) { [donation_1, donation_2, donation_3].map(&:id) }
  let(:item_a) { create(:item, organization: organization) }
  let(:item_b) { create(:item, organization: organization) }
  let(:donation_1) { create(:donation, :with_items, item: item_a, item_quantity: 500, organization: organization) }
  let(:donation_2) { create(:donation, :with_items, item: item_a, item_quantity: 500, organization: organization) }
  let(:donation_3) { create(:donation, :with_items, item: item_b, item_quantity: 500, organization: organization) }

  let(:expected_output) do
    [
      {name: item_a.name, donated: 1200, current_onhand: 1100},
      {name: item_b.name, donated: 500, current_onhand: 600}
    ]
  end

  describe "#fetch" do
    subject { described_class.new(organization: organization, donation_ids: donation_ids).fetch }

    it "return the list of items donated with distributed" do
      expect(subject).to eq(expected_output)
    end
  end
end
