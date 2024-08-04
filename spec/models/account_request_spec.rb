# == Schema Information
#
# Table name: account_requests
#
#  id                   :bigint           not null, primary key
#  confirmed_at         :datetime
#  email                :string           not null
#  name                 :string           not null
#  organization_name    :string           not null
#  organization_website :string
#  rejection_reason     :string
#  request_details      :text             not null
#  status               :string           default("started"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  ndbn_member_id       :bigint
#

RSpec.describe AccountRequest, type: :model do
  let(:account_request) { create(:account_request) }

  describe 'associations' do
    it { should have_one(:organization).class_name('Organization') }
    it { should belong_to(:ndbn_member).class_name("NDBNMember").optional }
  end

  describe 'validations' do
    subject { account_request }

    it { should validate_presence_of(:name) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }

    it { should validate_presence_of(:request_details) }
    it { should validate_length_of(:request_details).is_at_least(50) }

    it { should allow_value(Faker::Internet.email).for(:email) }
    it { should_not allow_value("not_email").for(:email) }

    it { should allow_value(Faker::Internet.url).for(:organization_website) }
    it { should_not allow_value("www.example.com").for(:organization_website) }

    context 'when the email provided is already used by an existing organization' do
      before do
        create(:organization, email: account_request.email)
      end

      it 'should not allow the email' do
        expect(subject.valid?).to eq(false)
        expect(subject.errors.messages[:email]).to match_array(["already used by an existing Organization"])
      end
    end

    context 'when the email provided is already used by an existing user' do
      before do
        FactoryBot.create(:user, email: account_request.email)
      end

      it 'should not allow the email' do
        expect(subject.valid?).to eq(false)
        expect(subject.errors.messages[:email]).to match_array(["already used by an existing User"])
      end
    end
  end

  describe '.get_by_identity_token' do
    subject { described_class.get_by_identity_token(identity_token) }

    context 'when the identity_token provided does not match any AccountRequest' do
      let(:identity_token) { 'not-a-real-token' }

      it 'should return nil' do
        expect(subject).to eq(nil)
      end
    end

    context 'when the identity_token corresponds to an existing AccountRequest' do
      let!(:account_request) { FactoryBot.create(:account_request) }
      let(:identity_token) { account_request.identity_token }

      it 'should return the corresponding AccountRequest' do
        expect(subject).to eq(account_request)
      end
    end
  end

  describe '#identity_token' do
    subject { account_request.identity_token }

    context 'when the account_request is not persisted' do
      before do
        allow(account_request).to receive(:persisted?).and_return(false)
      end

      it 'should raise an error' do
        expect { subject }.to raise_error('must have an id')
      end
    end

    it 'should return a JWT token that contains the id of the account_request_id' do
      token = subject
      decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
      expect(decoded_token[0]["account_request_id"]).to eq(account_request.id)
    end
  end

  describe '#processed?' do
    subject { account_request.processed? }

    context 'when the account request has no associated organization' do
      before do
        expect(account_request.organization).to eq(nil)
      end

      it 'should return false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the account request has a associated organization' do
      before do
        create(:organization, account_request_id: account_request.id)
      end

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end
  end

  specify '#confirm!' do
    mail_double = instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
    allow(AccountRequestMailer).to receive(:approval_request).and_return(mail_double)

    freeze_time do
      expect(account_request.confirmed_at).to be_nil

      account_request.confirm!

      expect(account_request.reload.confirmed_at).to eq(Time.zone.now)
      expect(account_request).to be_user_confirmed
      expect(AccountRequestMailer).to have_received(:approval_request)
        .with(account_request_id: account_request.id)
      expect(mail_double).to have_received(:deliver_later)
    end
  end

  specify '#reject!' do
    mail_double = instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
    allow(AccountRequestMailer).to receive(:rejection).and_return(mail_double)

    account_request.reject!('because I said so')

    expect(account_request.reload.rejection_reason).to eq('because I said so')
    expect(account_request).to be_rejected
    expect(AccountRequestMailer).to have_received(:rejection)
      .with(account_request_id: account_request.id)
    expect(mail_double).to have_received(:deliver_later)
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
