RSpec.describe PartnerRequestRecertificationService do
  describe '#call' do
    subject { described_class.new(partner: partner).call }
    let(:partner) { create(:partner) }
    let(:partner_profile) { partner.profile }

    before do
      partner.awaiting_review!
    end

    context 'when the arguments are incorrect' do
      context 'because the partner has already been requested to recertify' do
        before do
          partner.recertification_required!
        end

        it 'should return the PartnerRequestRecertificationService object with an error' do
          result = subject

          expect(result).to be_a_kind_of(PartnerRequestRecertificationService)
          expect(result.errors[:partner]).to eq(["has already been requested to recertify"])
        end
      end
    end

    context 'when the arguments are correct' do
      let(:fake_recertification_request) { double('mailer', deliver_later: -> {}) }
      before do
        allow(PartnerMailer).to receive(:recertification_request).with(partner: partner).and_return(fake_recertification_request)
      end

      it 'should have no errors' do
        expect(subject.errors).to be_empty
      end

      it 'should change the partner status to approved' do
        expect { subject }.to change { partner.reload.recertification_required? }.from(false).to(true)
      end

      it 'should queue sending the notice to the partner' do
        subject
        expect(fake_recertification_request).to have_received(:deliver_later)
      end

      context 'but a unexpected error occurred during the save' do
        let(:error_message) { 'boom' }

        context 'for partner approval' do
          before do
            allow(partner).to receive(:recertification_required!).and_raise(error_message)
          end

          it 'should have an error with the raised error' do
            expect(subject.errors[:base]).to eq([error_message])
          end

          it 'should not change the partner status to recertification_required' do
            expect { subject }.not_to change { partner.reload.approved? }
          end

          it 'should NOT queue sending the notice to the partner' do
            subject
            expect(fake_recertification_request).not_to have_received(:deliver_later)
          end
        end
      end
    end

    context 'when the partner is deactivated' do
      it 'does not send an email' do
        partner.update!(status: 'deactivated')
        expect(PartnerMailer).to_not receive(:recertification_request)
        result = subject
        expect(result.errors[:partner]).to eq(['has been deactivated'])
      end
    end
  end
end
