require "rails_helper"

RSpec.describe DiaperDriveHelper, type: :helper do
  describe '#is_virtual' do
    context 'when the diaper drive was held virtually' do
      let(:diaper_drive) { build(:diaper_drive, virtual: true) }
      subject { helper.is_virtual(diaper_drive: diaper_drive) }

      it { is_expected.to eq('Yes') }
    end

    context 'when the diaper drive wasn\'t held virtually' do
      let(:diaper_drive) { build(:diaper_drive, virtual: false) }
      subject { helper.is_virtual(diaper_drive: diaper_drive) }

      it { is_expected.to eq('No') }
    end

    context 'when a diaper drive was not provided' do
      it 'without argument' do
        expect { helper.is_virtual }.to raise_error(ArgumentError, 'missing keyword: :diaper_drive')
      end

      it 'with blank argument' do
        argument = [nil, '', {}].sample
        expect { helper.is_virtual(diaper_drive: argument) }.to raise_error(StandardError, 'No diaper drive was provided')
      end
    end
  end
end
