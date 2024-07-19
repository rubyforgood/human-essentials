RSpec.describe ProductDriveHelper, type: :helper do
  describe '#is_virtual' do
    context 'when the product drive was held virtually' do
      let(:product_drive) { build(:product_drive, virtual: true) }
      subject { helper.is_virtual(product_drive: product_drive) }

      it { is_expected.to eq('Yes') }
    end

    context 'when the product drive wasn\'t held virtually' do
      let(:product_drive) { build(:product_drive, virtual: false) }
      subject { helper.is_virtual(product_drive: product_drive) }

      it { is_expected.to eq('No') }
    end

    context 'when a product drive was not provided' do
      it 'without argument' do
        expect { helper.is_virtual }.to raise_error(ArgumentError, 'missing keyword: :product_drive')
      end

      it 'with blank argument' do
        argument = [nil, '', {}].sample
        expect { helper.is_virtual(product_drive: argument) }.to raise_error(StandardError, 'No product drive was provided')
      end
    end
  end
end
