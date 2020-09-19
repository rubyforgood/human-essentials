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
#  request_details      :text             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require 'rails_helper'

RSpec.describe AccountRequest, type: :model do
  describe 'associations' do
    it { should have_one(:organization).class_name('Organization') }
  end

  describe 'validations' do
    subject { account_request }
    let(:account_request) { FactoryBot.build(:account_request) }

    it { should validate_presence_of(:name) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }

    it { should validate_presence_of(:request_details) }
    it { should validate_length_of(:request_details).is_at_least(50) }

    it { should allow_value(Faker::Internet.email).for(:email) }
    it { should_not allow_value("not_email").for(:email) }

    context 'when the email provided is already used by an existing organization' do
      before do
        FactoryBot.create(:organization, email: account_request.email)
      end

      it 'should not allow the email' do
        expect(subject.valid?).to eq(false)
        expect(subject.errors.messages).to include({
                                                     email: [
                                                       "already used by an existing Organization"
                                                     ]
                                                   })
      end
    end

    context 'when the email provided is already used by an existing user' do
      before do
        FactoryBot.create(:user, email: account_request.email)
      end

      it 'should not allow the email' do
        expect(subject.valid?).to eq(false)
        expect(subject.errors.messages).to include({
                                                     email: [
                                                       "already used by an existing User"
                                                     ]
                                                   })
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
    let(:account_request) { FactoryBot.create(:account_request) }

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
      decoded_token = JWT.decode(token, Rails.application.secrets[:secret_key_base], true, { algorithm: 'HS256' })
      expect(decoded_token[0]["account_request_id"]).to eq(account_request.id)
    end
  end

  describe '#confirmed?' do
    subject { account_request.confirmed? }
    let(:account_request) { FactoryBot.create(:account_request) }

    context 'when confirmed_at is blank' do
      before do
        expect(account_request.confirmed_at).to eq(nil)
      end

      it 'should return false' do
        expect(subject).to eq(false)
      end
    end

    context 'when confirmed_at is not blank' do
      before do
        account_request.update!(confirmed_at: Time.current)
      end

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end
  end

  describe '#processed?' do
    subject { account_request.processed? }
    let(:account_request) { FactoryBot.create(:account_request) }

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
        FactoryBot.create(:organization, account_request_id: account_request.id)
      end

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end
  end
end
