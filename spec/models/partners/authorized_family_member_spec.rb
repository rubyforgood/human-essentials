# == Schema Information
#
# Table name: authorized_family_members
#
#  id            :bigint           not null, primary key
#  comments      :text
#  date_of_birth :date
#  first_name    :string
#  gender        :string
#  last_name     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  family_id     :bigint
#

RSpec.describe Partners::AuthorizedFamilyMember, type: :model do
  describe 'associations' do
    it { should belong_to(:family) }
    it { should have_many(:child_item_requests).dependent(:nullify) }
  end

  describe "#display_name" do
    let(:partners_family) { create(:partners_family) }
    let(:authorized_family_member) { partners_family.create_authorized }

    it "should return the family member's first and last name" do
      expect(authorized_family_member.display_name).to eq("#{authorized_family_member.first_name} #{authorized_family_member.last_name}")
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end


