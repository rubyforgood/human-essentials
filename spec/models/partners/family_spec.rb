# == Schema Information
#
# Table name: families
#
#  id                        :bigint           not null, primary key
#  case_manager              :string
#  comments                  :text
#  guardian_county           :string
#  guardian_employed         :boolean
#  guardian_employment_type  :jsonb
#  guardian_first_name       :string
#  guardian_health_insurance :jsonb
#  guardian_last_name        :string
#  guardian_monthly_pay      :decimal(, )
#  guardian_phone            :string
#  guardian_zip_code         :string
#  home_adult_count          :integer
#  home_child_count          :integer
#  home_young_child_count    :integer
#  military                  :boolean          default(FALSE)
#  sources_of_income         :jsonb
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  old_partner_id            :bigint
#  partner_id                :bigint
#

require "rails_helper"

RSpec.describe Partners::Family, type: :model do
  describe "associations" do
    it { should belong_to(:partner) }
    it { should have_many(:children).dependent(:destroy) }
    it { should have_many(:authorized_family_members).dependent(:destroy) }
  end

  describe "validations" do
    subject { partners_family }
    let(:partners_family) { FactoryBot.build(:partners_family) }

    it { should validate_presence_of(:guardian_first_name) }
    it { should validate_presence_of(:guardian_last_name) }
    it { should validate_presence_of(:guardian_zip_code) }
  end

  describe "#create_authorized" do
    subject { partners_family }
    let(:partners_family) { FactoryBot.create(:partners_family) }
    let(:authorized_family_member) { subject.create_authorized }

    it "should include authorized family members" do
      expect(subject.authorized_family_members).to include(authorized_family_member)
    end
  end

  describe "#guardian_display_name" do
    subject { partners_family }
    let(:partners_family) { FactoryBot.build(:partners_family) }

    it "should return the guardian's first and last name" do
      expect(subject.guardian_display_name).to eq("#{subject.guardian_first_name} #{subject.guardian_last_name}")
    end
  end

  describe "#total_children_count" do
    subject { partners_family }
    let(:partners_family) { FactoryBot.build(:partners_family) }

    it "should return the family's total children count" do
      expect(subject.total_children_count).to eq(subject.home_child_count + subject.home_young_child_count)
    end
  end
end
