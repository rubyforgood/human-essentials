RSpec.describe PartnerApprovalService do
  describe '#call' do
    subject { described_class.new(partner: partner).call }
    let(:partner) { create(:partner) }
    let(:partner_profile) { partner.profile }

    before do
      partner.awaiting_review!
    end

    context 'when the arguments are incorrect' do
      context 'because the partner is not approvable' do
        before do
          allow(partner).to receive(:approvable?).and_return(false)
        end

        it 'should return the PartnerApprovalService object with an error' do
          result = subject

          expect(result).to be_a_kind_of(PartnerApprovalService)
          expect(result.errors[:partner]).to eq(["is not waiting for approval"])
        end
      end
    end

    context 'when the arguments are correct' do
      let(:fake_mailer) { double('fake_mailer', deliver_later: -> {}) }
      before do
        allow(PartnerMailer).to receive(:application_approved).with(partner: partner).and_return(fake_mailer)
      end

      it 'should have no errors' do
        expect(subject.errors).to be_empty
      end

      it 'should change the partner status to approved' do
        expect { subject }.to change { partner.reload.approved? }.from(false).to(true)
      end

      it 'should send an email notification to the partner' do
        subject
        expect(fake_mailer).to have_received(:deliver_later)
      end

      context 'but a unexpected error occured during the save' do
        let(:error_message) { 'boom' }

        context 'for partner approval' do
          before do
            allow(partner).to receive(:approved!).and_raise(error_message)
          end

          it 'should have an error with the raised error' do
            expect(subject.errors[:base]).to eq([error_message])
          end

          it 'should not change the partner status to approved' do
            expect { subject }.not_to change { partner.reload.approved? }
          end

          it 'should not send an email notification to the partner' do
            subject
            expect(fake_mailer).to_not have_received(:deliver_later)
          end
        end
      end
    end
  end
end
