require "rails_helper"

RSpec.describe DiaperDriveHelper, type: :helper do
  describe '#is_virtual' do
    context 'when diaper drive was held virtually' do
      let(:diaper_drive) { build(:diaper_drive, virtual: true) }
      subject { helper.is_virtual(diaper_drive) }

      it { is_expected.to eq('Yes') }
    end

    context 'when diaper drive wasn\'t held virtually' do
      let(:diaper_drive) { build(:diaper_drive, virtual: false) }
      subject { helper.is_virtual(diaper_drive) }

      it { is_expected.to eq('No') }
    end

    context 'when diaper drive is not informed' do
      let(:diaper_drive) { nil }
      subject { helper.is_virtual(diaper_drive) }

      it { is_expected.to eq('No') }
    end
  end
end
