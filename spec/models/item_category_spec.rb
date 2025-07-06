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
    it { should validate_length_of(:description).is_at_most(250) }
  end

  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:items) }
    it { should have_and_belong_to_many(:partner_groups) }
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end

  describe "delete" do
    let(:item_category) { create(:item_category) }
    let(:partner_group) { create(:partner_group, item_categories: [item_category]) }

    before do
      partner_group
    end

    it "should not delete if associated with partner groups" do
      expect(item_category.partner_groups).not_to be_empty
      expect { item_category.destroy }.not_to change(ItemCategory, :count)
      expect(item_category.errors.full_messages).to include("Cannot delete item category with associated partner groups")
    end

    it "should delete if not associated with partner groups" do
      item_category.partner_groups.destroy_all
      expect { item_category.destroy }.to change(ItemCategory, :count).by(-1)
    end
  end
end
