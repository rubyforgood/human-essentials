RSpec.describe Partners::RequestApprovalService do
  describe '#call' do
    subject { described_class.new(partner: partner).call }
    let(:partner) { create(:partner) }

    context 'when the partner is already awaiting approval' do
      before do
        partner.update!(status: 'awaiting_review')
      end

      it 'should return an error saying it the partner is already requested approval' do
        expect(subject.errors[:base]).to include("This partner has already requested approval.")
      end
    end

    context 'when the partner is not yet waiting for approval and there is a profile error' do
      it 'should return an error re social media' do
        partner.profile.update(website: '', facebook: '', twitter: '', instagram: '', no_social_media_presence: false)

        expect(subject.errors.full_messages)
          .to include("No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.")
      end

      # TODO: This test is disabled until we sort out required fields, per
      # https://github.com/rubyforgood/human-essentials/issues/3875
      xit 'should return an error re agency_type' do
        partner.profile.update(agency_type: "")

        expect(subject.errors.full_messages)
          .to include("Agency type can't be blank")
      end
    end

    context 'when the partner is not yet waiting for approval and there is no profile error' do
      it 'does not have an error' do
        partner.profile.update(website: 'website URL', facebook: '', twitter: '', instagram: '', no_social_media_presence: false)
        expect(subject.errors.full_messages).to be_empty
      end
    end

    context 'when the partner is not yet awaiting approval' do
      let(:fake_mailer) { double('fake_mailer', deliver_later: -> {}) }
      before do
        allow(OrganizationMailer).to receive(:partner_approval_request).with(partner: partner, organization: partner.organization).and_return(fake_mailer)
        expect(partner.status).not_to eq(:awaiting_review)
        partner.profile.update(website: 'website URL')
      end

      it 'should set the status on the partner record to awaiting_review' do
        expect { subject }.to change { partner.awaiting_review? }.from(false).to(true)
      end

      it 'should send an email notification to the partner\'s organization' do
        subject
        expect(fake_mailer).to have_received(:deliver_later)
      end
    end
  end
end
