# == Schema Information
#
# Table name: partner_requests
#
#  id              :bigint           not null, primary key
#  comments        :text
#  for_families    :boolean
#  sent            :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#  partner_id      :bigint
#  partner_user_id :integer
#
require "rails_helper"

RSpec.describe Partners::Request, type: :model, skip_seed: true do
  describe 'associations' do
    it { should belong_to(:partner) }
    it { should have_many(:item_requests).dependent(:destroy) }
    it { should have_many(:child_item_requests).through(:item_requests) }
  end

  describe 'validations' do
    it { should validate_presence_of(:partner) }
    it { should validate_presence_of(:partner_user_id).on(:create) }
    it { should accept_nested_attributes_for(:item_requests) }
  end

  describe '#partner_user' do
    subject { partner_request.partner_user }
    let(:user) { create(:user) }
    let(:partner_request) { Partners::Request.new(partner_user_id: user.id) }

    it 'should run the User record associated to the partner_user_id' do
      expect(subject).to eq(user)
    end
  end
end


