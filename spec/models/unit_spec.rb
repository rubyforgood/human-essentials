# == Schema Information
#
# Table name: units
#
#  id              :bigint           not null, primary key
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

RSpec.describe Unit, type: :model do
  let!(:organization) { create(:organization) }
  let!(:unit_1) { create(:unit, name: "WolfPack", organization: organization) }

  describe "Validations" do
    it "validates uniqueness of name in context of organization" do
      expect { described_class.create!(name: "WolfPack", organization: organization) }.to raise_exception(ActiveRecord::RecordInvalid).with_message("Validation failed: Name has already been taken")
    end
  end

  describe "Associations" do
    it { should belong_to(:organization) }
  end
end
