# == Schema Information
#
# Table name: roles
#
#  id              :bigint           not null, primary key
#  name            :string
#  resource_type   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  old_resource_id :bigint
#  resource_id     :bigint
#

RSpec.describe Role, type: :model do
  describe "Validations" do
    it { should validate_inclusion_of(:resource_type).in_array(Rolify.resource_types) }
  end

  describe "Associations" do
    it { should have_and_belong_to_many(:users) }
    it { should belong_to(:resource).optional }
  end

  it { should accept_nested_attributes_for :users }

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
