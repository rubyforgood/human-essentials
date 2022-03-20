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
    it { should validate_presence_of(:partner_user).on(:create) }
    it { should accept_nested_attributes_for(:item_requests) }
  end
end


