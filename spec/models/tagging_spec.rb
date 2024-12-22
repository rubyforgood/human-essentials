# == Schema Information
#
# Table name: taggings
#
#  id              :bigint           not null, primary key
#  taggable_type   :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#  tag_id          :bigint           not null
#  taggable_id     :bigint           not null
#
RSpec.describe Tagging, type: :model do
  describe "assocations" do
    it { should belong_to(:tag) }
    it { should belong_to(:taggable) }
    it { should belong_to(:organization) }
  end

  describe "scopes" do
    describe "by_type" do
      let!(:tag) { create(:tag) }
      let!(:organization) { create(:organization) }
      let!(:product_drive) { create(:product_drive, organization:) }
      let!(:purchase) { create(:purchase, organization:) }
      let!(:product_drive_tagging) { create(:tagging, taggable: product_drive, organization:, tag:) }
      let!(:purchase_tagging) { create(:tagging, taggable: purchase, organization:, tag:) }

      it "only displays taggings of that type" do
        type = "ProductDrive"
        expect(described_class.by_type(type)).to eq([product_drive_tagging])
      end
    end
  end
end
