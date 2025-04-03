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

    it "doesn't allow unit, units, Unit, or Units" do
      expect { described_class.create!(name: "unit", organization: organization) }.to raise_exception(ActiveRecord::RecordInvalid).with_message("Validation failed: Name 'unit' is reserved.")
      expect { described_class.create!(name: "units", organization: organization) }.to raise_exception(ActiveRecord::RecordInvalid).with_message("Validation failed: Name 'unit' is reserved.")
      expect { described_class.create!(name: "Unit", organization: organization) }.to raise_exception(ActiveRecord::RecordInvalid).with_message("Validation failed: Name 'unit' is reserved.")
      expect { described_class.create!(name: "Units", organization: organization) }.to raise_exception(ActiveRecord::RecordInvalid).with_message("Validation failed: Name 'unit' is reserved.")
    end
  end

  describe "Associations" do
    it { should belong_to(:organization) }
  end
end
