# == Schema Information
#
# Table name: children
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  archived             :boolean
#  child_lives_with     :jsonb
#  comments             :text
#  date_of_birth        :date
#  first_name           :string
#  gender               :string
#  health_insurance     :jsonb
#  item_needed_diaperid :integer
#  last_name            :string
#  race                 :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  agency_child_id      :string
#  family_id            :bigint
#

RSpec.describe Partners::Child, type: :model do
  describe 'associations' do
    it { should belong_to(:family) }
    it { should have_many(:child_item_requests).dependent(:destroy) }
    it { should have_and_belong_to_many(:requested_items).class_name('Item') }
  end

  describe "#display_name" do
    subject { partners_child }
    let(:partners_child) { create(:partners_child) }

    it "should return a child's first and last name" do
      expect(subject.display_name).to eq("#{subject.first_name} #{subject.last_name}")
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
