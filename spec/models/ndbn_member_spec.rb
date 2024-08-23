# == Schema Information
#
# Table name: ndbn_members
#
#  account_name   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  ndbn_member_id :bigint           not null, primary key
#

RSpec.describe NDBNMember, type: :model do
  describe "validations" do
    subject { build(:ndbn_member) }
    it { should validate_presence_of(:ndbn_member_id) }
    it { should validate_presence_of(:account_name) }
    it { should validate_uniqueness_of(:ndbn_member_id) }
  end

  describe "#full_name" do
    subject { ndbn_member.full_name }
    let(:ndbn_member) { build(:ndbn_member) }

    it "should equal the id and the account name" do
      expect(subject).to eq("#{ndbn_member.ndbn_member_id} - #{ndbn_member.account_name}")
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
