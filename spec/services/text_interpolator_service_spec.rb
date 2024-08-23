RSpec.describe TextInterpolatorService, type: :service do
  describe '#call' do
    subject { described_class.new(text, interpolations).call }

    let(:text) { 'Hello, %{name}!' }
    let(:interpolations) { { name: 'Alejandro' } }

    it 'returns interpolated text' do
      expect(subject).to eq 'Hello, Alejandro!'
    end

    context 'when text is nil' do
      let(:text) { nil }

      it 'returns nil' do
        expect(subject).to eq nil
      end
    end

    context 'when text is empty' do
      let(:text) { '' }

      it 'returns empty string' do
        expect(subject).to eq ''
      end
    end

    context 'when interpolations are nil' do
      let(:interpolations) { nil }

      it 'returns text' do
        expect(subject).to eq 'Hello, !'
      end
    end

    context 'when interpolations are empty' do
      let(:interpolations) { {} }

      it 'returns text' do
        expect(subject).to eq 'Hello, !'
      end
    end

    context 'when interpolations are not present' do
      let(:interpolations) { { name: nil } }

      it 'returns text' do
        expect(subject).to eq 'Hello, !'
      end
    end
  end
end
