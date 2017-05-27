# == Schema Information
#
# Table name: adjustments
#
#  id                  :integer          not null, primary key
#  organization_id     :integer
#  storage_location_id :integer
#  comment             :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'rails_helper'

RSpec.describe Adjustment, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:adjustment, organization_id: nil)).not_to be_valid
    end
  end

  describe 'nested line item attributes' do
    it 'accepts them' do
      item = create(:item)
      storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)

      new_adjustment = build(:adjustment,
                             storage_location: storage_location,
                             line_items_attributes: [
                               { item_id: storage_location.items.first.id, quantity: 10 }
                             ])

      expect(new_adjustment.save).to be_truthy
    end

  end
end
