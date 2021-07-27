# == Schema Information
#
# Table name: item_categories
#
#  id              :bigint           not null, primary key
#  description     :text
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
require 'rails_helper'

RSpec.describe ItemCategory, type: :model do
  describe 'validations' do
    subject { build(:item_category) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:organization_id) }
    it { should validate_presence_of(:organization) }
    it { should validate_length_of(:description).is_at_most(250) }
  end

  describe 'assocations' do
    it { should belong_to(:organization) }
    it { should have_many(:items) }
  end
end
