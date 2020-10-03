RSpec.describe RequestsTotalItemsService, type: :service do
  describe '#calculate' do
    it 'return items with quantities calculated' do
      items = Item.active.sample(3)
      items_id = items.pluck(:id)
      requests = [
        create(:request, request_items: request_items(items_id, 20)),
        create(:request, request_items: request_items(items_id, 10))
      ]

      items_calculated = described_class.calculate(requests)
      expect(total_first_item(items_calculated)).to eq(30)
    end

    it 'return blank when requests itens is blank' do
      request = create(:request, request_items: {})
      expect(described_class.calculate([request])).to be_blank
    end

    it 'return blank when requests is nil' do
      expect(described_class.calculate(nil)).to be_blank
    end
  end

  def total_first_item(items_calculated)
    items_calculated.first.last
  end

  def request_items(items_id, quantity)
    items_id.map { |k| { "item_id" => k, "quantity" => quantity } }
  end
end
