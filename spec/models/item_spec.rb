# == Schema Information
#
# Table name: items
#
#  id            :integer          not null, primary key
#  name          :string
#  category      :string
#  created_at    :datetime
#  updated_at    :datetime
#  barcode_count :integer
#

require "rails_helper"

RSpec.describe Item, type: :model do
  context "Validations >" do
    it "requires a name" do
      expect(build(:item, name: nil)).not_to be_valid
    end
  end
end
