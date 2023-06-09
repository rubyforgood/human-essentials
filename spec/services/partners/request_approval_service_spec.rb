require 'rails_helper'

describe Partners::RequestApprovalService do
  describe '#call' do
    subject { described_class.new(partner: partner).call }
    let(:partner) { create(:partner) }

    it 'should return an instance of itself' do
      expect(subject).to be_a_kind_of(Partners::RequestApprovalService)
    end

    context 'when the partner is already awaiting approval' do
      before do
        partner.update!(status: 'awaiting_review')
      end

      it 'should return an error saying it the partner is already requested approval' do
        expect(subject.errors[:base]).to eq(["This partner has already requested approval."])
      end
    end

    context 'when the partner is not yet waiting for approval and the media information is blank' do
      it 'should return an error' do
        partner.profile.update(website: '', facebook: '', twitter: '', instagram: '', no_social_media_presence: false)
        expect(subject.errors[:base]).to eq(['You must either provide a social media site or indicate that you have no social media presence before submitting for approval.'])
      end
    end

    context 'when the partner is not yet waiting for approval and the media information is not blank it should not throw an error' do
      it 'with a website' do
        partner.profile.update(website: 'website URL', facebook: '', twitter: '', instagram: '', no_social_media_presence: false)
        expect(subject.errors[:base]).to eq([])
      end

      it 'with facebook' do
        partner.profile.update(website: '', facebook: 'facebook URL', twitter: '', instagram: '', no_social_media_presence: false)
        expect(subject.errors[:base]).to eq([])
      end

      it 'with twitter' do
        partner.profile.update(website: '', facebook: '', twitter: 'twitter URL', instagram: '', no_social_media_presence: false)
        expect(subject.errors[:base]).to eq([])
      end

      it 'with instagram' do
        partner.profile.update(website: '', facebook: '', twitter: '', instagram: 'instagram URL', no_social_media_presence: false)
        expect(subject.errors[:base]).to eq([])
      end

      it 'with all social media options' do
        partner.profile.update(website: 'website URL', facebook: 'facebook URL', twitter: 'twitter URL', instagram: 'instagram URL', no_social_media_presence: false)
        expect(subject.errors[:base]).to eq([])
      end

      it 'with no social media but the checkbox is checked' do
        partner.profile.update(website: '', facebook: '', twitter: '', instagram: '', no_social_media_presence: true)
        expect(subject.errors[:base]).to eq([])
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
