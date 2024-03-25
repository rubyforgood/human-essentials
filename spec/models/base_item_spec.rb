# == Schema Information
#
# Table name: base_items
#
#  id            :bigint           not null, primary key
#  barcode_count :integer
#  category      :string
#  item_count    :integer
#  name          :string
#  partner_key   :string
#  size          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require "rails_helper"

RSpec.describe BaseItem, type: :model, seed_items: false do
  let(:organization) { create(:organization, skip_items: true) }

  describe "Validations >" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:partner_key) }
    it { should validate_uniqueness_of(:partner_key) }
  end

  describe "Associations >" do
    it "keeps count of its associated items" do
      c = create(:base_item, name: "Base", item_count: 0) # BUG: should this default to 0?
      expect { create_list(:item, 2, base_item: c) }.to change { c.item_count }.by(2)
    end
  end

  describe "Methods >" do
    describe '.seed_items' do
      let(:fake_base_items_data) do
        {
          'category1' => [
            {'name' => 'Item1', 'key' => 'key1'},
            {'name' => 'Item2', 'key' => 'key2'}
          ],
          'category2' => [
            {'name' => 'Item3', 'key' => 'key3'}
          ]
        }
      end

      before do
        allow(File).to receive(:read).with(Rails.root.join("db", "base_items.json")).and_return('')
        allow(JSON).to receive(:parse).and_return(fake_base_items_data)
      end

      it 'creates base items' do
        expect {
          described_class.seed_items
        }.to change(BaseItem, :count).by(3)
      end

      it 'creates base items with correct attributes' do
        described_class.seed_items

        expect(BaseItem.exists?(name: 'Item1', category: 'category1', partner_key: 'key1')).to be_truthy
        expect(BaseItem.exists?(name: 'Item2', category: 'category1', partner_key: 'key2')).to be_truthy
        expect(BaseItem.exists?(name: 'Item3', category: 'category2', partner_key: 'key3')).to be_truthy
      end
    end
  end

  describe "Filtering >" do
    describe '->without_kit' do
      subject { BaseItem.without_kit }

      let!(:kit_base_item) { BaseItem.find_by(name: 'Kit') }
      it 'should not include the Kit BaseItem' do
        expect(subject).not_to include(kit_base_item)
      end
    end

    describe "->by_partner_key" do
      it "shows the Base Items by partner_key" do
        base_item = create(:base_item)
        expect(BaseItem.by_partner_key(base_item.partner_key).size).to eq(1)
        expect(BaseItem.by_partner_key("random_string").size).to eq(0)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
