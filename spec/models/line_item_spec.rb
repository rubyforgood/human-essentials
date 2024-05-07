# == Schema Information
#
# Table name: line_items
#
#  id              :integer          not null, primary key
#  itemizable_type :string
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  item_id         :integer
#  itemizable_id   :integer
#

RSpec.describe LineItem, type: :model, skip_seed: true do
  let(:line_item) { build :line_item }

  context "Validations >" do
    subject { line_item }

    it { should validate_numericality_of(:quantity).is_greater_than(-2**31) }
    it { should validate_numericality_of(:quantity).is_less_than(2**31) }
    it { should validate_numericality_of(:quantity).only_integer }
  end

  describe "package_count" do
    it "is equal to the quanity divided by the package_size" do
      item = create(:item, package_size: 10)
      line_item = create(:line_item, :purchase, quantity: 100, item_id: item.id)
      expect(line_item.package_count).to eq("10")
    end

    it "is nil if there is no package_size" do
      item = create(:item)
      line_item = create(:line_item, :purchase, quantity: 100, item_id: item.id)
      expect(line_item.package_count).to be_nil
    end
  end

  describe "Scopes >" do
    describe "->active" do
      it "retrieves only those with active status" do
        expect do
          create(:line_item, :purchase, item: create(:item, :active))
          create(:line_item, :purchase, item: create(:item, :inactive))
        end.to change { described_class.active.size }.by(1)
      end
    end
  end

  describe 'Methods >' do
    context '#value_per_line_item' do
      subject { line_item.value_per_line_item }

      describe 'item has no value' do
        it { is_expected.to eq(0) }
      end

      describe 'item has value and quantity' do
        let(:value) { 5 }
        let(:quantity) { 5 }

        before do
          line_item.item = create(:item, value_in_cents: value)
          line_item.quantity = quantity
        end

        it { is_expected.to eq(value * quantity) }
      end
    end

    context 'item packages' do
      let(:package_size) { 5 }
      let(:quantity) { 5 }

      context '#has_packages' do
        subject { line_item.has_packages }

        describe 'item has no package size' do
          it { is_expected.to be_falsy }
        end

        describe 'item has package size' do
          before do
            line_item.item = create(:item, package_size: package_size)
            line_item.quantity = quantity
          end

          it { is_expected.to be_truthy }
        end
      end

      context '#package_count' do
        subject { line_item.package_count }

        describe 'has packages' do
          before do
            line_item.item = create(:item, package_size: package_size)
            line_item.quantity = quantity
          end

          it { is_expected.to eq((quantity / package_size).to_s) }
        end

        describe 'does not have packages' do
          it { is_expected.to be_falsy }
        end
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
