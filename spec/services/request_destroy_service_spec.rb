RSpec.describe RequestDestroyService, type: :service do
  describe '#call' do
    subject { described_class.new(request_id: request_id).call }
    let(:request_id) { request.id }
    let(:request) { create(:request) }

    it 'should return an instance of itself' do
      expect(subject).to be_a_kind_of(RequestDestroyService)
    end

    context 'when the request_id matches no request' do
      let(:request_id) { 0 }

      it 'should not be successful and have errors indicating request id is invalid' do
        expect(subject.errors.full_messages).to eq(['request_id is invalid'])
      end
    end

    context 'when the request is already discarded' do
      before do
        request.discard!
      end

      it 'should not be successful and have errors' do
        expect(subject.errors.full_messages).to eq(['request already discarded'])
      end
    end

    context 'when there are no validation errors' do
      it 'should update the discarded_at column on the request' do
        expect { subject }.to change { request.reload.discarded? }.from(false).to(true)
      end
    end

  end
end

