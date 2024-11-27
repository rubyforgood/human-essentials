# == Schema Information
#
# Table name: item_categories
#
#  id              :bigint           not null, primary key
#  description     :text
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#

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
    it { should have_and_belong_to_many(:partner_groups) }
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
