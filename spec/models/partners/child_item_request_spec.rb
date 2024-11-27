# == Schema Information
#
# Table name: child_item_requests
#
#  id                          :bigint           not null, primary key
#  picked_up                   :boolean          default(FALSE)
#  picked_up_item_diaperid     :integer
#  quantity_picked_up          :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  authorized_family_member_id :integer
#  child_id                    :bigint
#  item_request_id             :bigint
#

RSpec.describe Partners::ChildItemRequest, type: :model do
  describe 'associations' do
    it { should belong_to(:item_request) }
    it { should belong_to(:child) }
    it { should belong_to(:authorized_family_member).optional }
  end

  describe '#quantity' do
    subject { child_item_request.quantity }
    let(:child_item_request) { described_class.new }
    let(:quantity) { 4 }
    let(:child_count) { 2 }
    before do
      allow(child_item_request).to receive_message_chain(:item_request, :quantity).and_return(quantity)
      allow(child_item_request).to receive_message_chain(:item_request, :children, :size).and_return(child_count)
    end

    it 'should return the quantity divided by the number of children' do
      expect(subject).to eq(quantity / child_count)
    end
  end

  describe '#ordered_item_diaperid' do
    subject { child_item_request.ordered_item_diaperid }
    let(:child_item_request) { described_class.new }
    let(:item_id) { 3 }
    before do
      allow(child_item_request).to receive_message_chain(:item_request, :item_id).and_return(item_id)
    end

    it 'should return the item_id on the item_request' do
      expect(subject).to eq(item_id)
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
