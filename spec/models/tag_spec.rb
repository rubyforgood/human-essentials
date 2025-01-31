# == Schema Information
#
# Table name: tags
#
#  id              :bigint           not null, primary key
#  name            :string(256)      not null
#  type            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#
RSpec.describe Tag, type: :model do
  let(:organization) { build(:organization) }

  describe "validations" do
    subject { build(:tag, organization:) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(256) }
  end

  describe "assocations" do
    it { should have_many(:taggings) }
    it { should belong_to(:organization) }
  end

  describe "scopes" do
    describe "alphabetized" do
      let!(:z_tag) { create(:tag, name: "Z", organization:) }
      let!(:a_tag) { create(:tag, name: "A", organization:) }

      it "retrieves tags in the correct order" do
        alphabetized_list = described_class.alphabetized

        expect(alphabetized_list.first).to eq(a_tag)
        expect(alphabetized_list.last).to eq(z_tag)
      end
    end

    describe "by_type" do
      let!(:tag) { create(:tag) }
      let!(:product_drive) { create(:product_drive, organization:) }
      let!(:purchase) { create(:purchase, organization:) }
      let!(:product_drive_tagging) { create(:tagging, taggable: product_drive, tag:) }
      let!(:purchase_tagging) { create(:tagging, taggable: purchase, tag:) }

      it "only displays taggings of that type" do
        type = "ProductDrive"
        expect(described_class.by_type(type)).to eq([tag])
      end
    end
  end
end
