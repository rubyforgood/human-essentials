# == Schema Information
#
# Table name: item_requests
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  partner_key            :string
#  quantity               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  item_id                :integer
#  old_partner_request_id :integer
#  partner_request_id     :bigint
#
require "rails_helper"

RSpec.describe Partners::ItemRequest, type: :model do
  describe 'associations' do
    it { should belong_to(:request).class_name('::Request').with_foreign_key(:partner_request_id) }
    it { should have_many(:child_item_requests).dependent(:destroy) }
    it { should have_many(:children).through(:child_item_requests) }
  end

  describe 'validations' do
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(1) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:partner_key) }
  end
end


