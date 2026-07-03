# == Schema Information
#
# Table name: children
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  archived             :boolean
#  child_lives_with     :jsonb
#  comments             :text
#  date_of_birth        :text
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

  describe "encrypts date_of_birth at rest" do
    let(:child) { create(:partners_child, date_of_birth: Date.new(2020, 1, 1)) }

    it "stores ciphertext but round-trips as a Date" do
      expect(child.reload.date_of_birth).to eq(Date.new(2020, 1, 1))
      expect(child.date_of_birth).to be_a(Date)
      expect(child.ciphertext_for(:date_of_birth)).not_to include("2020-01-01")
    end
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
