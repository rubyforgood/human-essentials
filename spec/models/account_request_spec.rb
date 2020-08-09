# == Schema Information
#
# Table name: account_requests
#
#  id                   :bigint           not null, primary key
#  email                :string           not null
#  organization_name    :string           not null
#  organization_website :string
#  request_details      :text             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require 'rails_helper'

RSpec.describe AccountRequest, type: :model do
  describe 'validations' do
    subject { account_request }
    let(:account_request) { FactoryBot.build(:account_request) }

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
end
