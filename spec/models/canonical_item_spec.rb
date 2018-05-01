# == Schema Information
#
# Table name: canonical_items
#
#  id            :integer          not null, primary key
#  key           :string
#  name          :string
#  barcode_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'rails_helper'

RSpec.describe CanonicalItem, type: :model do
  describe "Validations >" do
    it "is invalid without a key" do
      expect(build(:canonical_item, key: nil)).not_to be_valid
    end

    it "is invalid without a name" do
      expect(build(:canonical_item, name: nil)).not_to be_valid
    end
  end

  describe "Associations >" do
  end
end
