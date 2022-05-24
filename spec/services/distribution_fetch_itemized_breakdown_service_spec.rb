RSpec.describe DistributionFetchItemizedBreakdownService, type: :service, skip_seed: true do

  describe '.fetch(as_csv: false)' do
    subject { service.fetch(as_csv: as_csv) }
    let(:service) { described_class.new(organization: organization, distribution_ids: distribution_ids) }
    let(:organization) { create(:organization) }
    let(:distribution_ids) { distributions.pluck(:id) }
    let(:distributions) { create_list(:distribution, 2, :with_items, item_quantity: distribution_per_item, organization: organization) }
    let(:distribution_per_item) { 50 }
    let(:as_csv) { false }
    let(:expected_output) do
      distributions.map(&:items).flatten.inject({}) do |acc, item|
        acc[item.name] ||= {}
        acc[item.name] = {
          distributed: distribution_per_item,
          current_onhand: InventoryItem.find_by(item_id: item.id).quantity,
          onhand_minimum: item.on_hand_minimum_quantity,
          below_onhand_minimum: item.on_hand_minimum_quantity > InventoryItem.find_by(item_id: item.id).quantity
        }

        acc
      end
    end

    before do
      # Force one of onhand minimums to be very high so that we can see it turns out true
      distributions.last.items.first.update_column(:on_hand_minimum_quantity, 9999)
    end

    it 'should include the break down of items distributed with onhand data' do
      expect(subject).to eq(expected_output)
    end

    context 'when as_csv is set to true' do
      let(:as_csv) { true }

      it 'should output the expected output but in CSV format' do
        expected_output_csv = CSV.generate do |csv|
          csv << ["Item", "Total Distribution", "Total On Hand"]

          expected_output.sort_by { |name, value| -value[:distributed] }.each do |key, value|
            csv << [key, value[:distributed], value[:current_onhand]]
          end
        end
        
        expect(subject).to eq(expected_output_csv)
      end
    end

  end
end
