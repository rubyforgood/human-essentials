# == Schema Information
#
# Table name: families
#
#  id                        :bigint           not null, primary key
#  comments                  :text
#  guardian_country          :string
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
#  agency_guardian_id        :string
#  partner_id                :bigint
#

require "rails_helper"

RSpec.describe Partners::Family, type: :model, skip_seed: true do
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

  describe "#csv_headers" do
    subject { Partners::Family }
    let(:csv_headers) do
      %w[
        id guardian_first_name guardian_last_name guardian_zip_code guardian_country
        guardian_phone agency_guardian_id home_adult_count home_child_count home_young_child_count
        sources_of_income guardian_employed guardian_employment_type guardian_monthly_pay
        guardian_health_insurance comments created_at updated_at partner_id military
      ]
    end

    it "should have correct csv headers" do
      expect(subject.csv_headers).to eq(csv_headers)
    end
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

  describe "#to_csv" do
    subject { partners_family }
    let(:partners_family) { FactoryBot.create(:partners_family) }
    let(:csv_array) do
      [
        subject.id,
        subject.guardian_first_name,
        subject.guardian_last_name,
        subject.guardian_zip_code,
        subject.guardian_country,
        subject.guardian_phone,
        subject.agency_guardian_id,
        subject.home_adult_count,
        subject.home_child_count,
        subject.home_young_child_count,
        subject.sources_of_income,
        subject.guardian_employed,
        subject.guardian_employment_type,
        subject.guardian_monthly_pay,
        subject.guardian_health_insurance,
        subject.comments,
        subject.created_at,
        subject.updated_at,
        subject.partner_id,
        subject.military
      ]
    end

    it "should return an array of values" do
      expect(subject.to_csv).to eq(csv_array)
    end
  end
end
