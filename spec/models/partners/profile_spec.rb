# == Schema Information
#
# Table name: partner_profiles
#
#  id                             :bigint           not null, primary key
#  above_1_2_times_fpl            :integer
#  address1                       :string
#  address2                       :string
#  agency_mission                 :text
#  agency_type                    :string
#  application_data               :text
#  at_fpl_or_below                :integer
#  case_management                :boolean
#  city                           :string
#  client_capacity                :string
#  currently_provide_diapers      :boolean
#  describe_storage_space         :text
#  distribution_times             :string
#  distributor_type               :string
#  enable_child_based_requests    :boolean          default(TRUE), not null
#  enable_individual_requests     :boolean          default(TRUE), not null
#  essentials_budget              :string
#  essentials_funding_source      :string
#  essentials_use                 :string
#  evidence_based                 :boolean
#  executive_director_email       :string
#  executive_director_name        :string
#  executive_director_phone       :string
#  facebook                       :string
#  form_990                       :boolean
#  founded                        :integer
#  greater_2_times_fpl            :integer
#  income_requirement_desc        :boolean
#  income_verification            :boolean
#  more_docs_required             :string
#  name                           :string
#  new_client_times               :string
#  other_agency_type              :string
#  partner_status                 :string           default("pending")
#  pick_up_email                  :string
#  pick_up_name                   :string
#  pick_up_phone                  :string
#  population_american_indian     :integer
#  population_asian               :integer
#  population_black               :integer
#  population_hispanic            :integer
#  population_island              :integer
#  population_multi_racial        :integer
#  population_other               :integer
#  population_white               :integer
#  poverty_unknown                :integer
#  primary_contact_email          :string
#  primary_contact_mobile         :string
#  primary_contact_name           :string
#  primary_contact_phone          :string
#  program_address1               :string
#  program_address2               :string
#  program_age                    :string
#  program_city                   :string
#  program_description            :text
#  program_name                   :string
#  program_state                  :string
#  program_zip_code               :integer
#  receives_essentials_from_other :string
#  sources_of_diapers             :string
#  sources_of_funding             :string
#  state                          :string
#  status_in_diaper_base          :string
#  storage_space                  :boolean
#  twitter                        :string
#  website                        :string
#  zip_code                       :string
#  zips_served                    :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  essentials_bank_id             :bigint
#  partner_id                     :integer
#
require "rails_helper"

RSpec.describe Partners::Profile, type: :model do
  describe "associations" do
    it { should have_one_attached(:proof_of_partner_status) }
    it { should have_one_attached(:proof_of_form_990) }
    it { should have_many_attached(:documents) }
  end

  describe "#impact_metrics" do
    subject { partner.impact_metrics }
    let(:partner) { FactoryBot.create(:partner) }

    context "when partner has related informations" do
      let!(:family1) { FactoryBot.create(:partners_family, guardian_zip_code: "45612-123", partner: partner) }
      let!(:family2) { FactoryBot.create(:partners_family, guardian_zip_code: "45612-126", partner: partner) }
      let!(:family3) { FactoryBot.create(:partners_family, guardian_zip_code: "45612-123", partner: partner) }

      let!(:child1) { FactoryBot.create_list(:partners_child, 2, family: family1) }
      let!(:child2) { FactoryBot.create_list(:partners_child, 2, family: family3) }

      it { is_expected.to eq({families_served: 3, children_served: 4, family_zipcodes: 2, family_zipcodes_list: %w[45612-123 45612-126]}) }
    end

    context "when partner don't have any related informations" do
      it { is_expected.to eq({families_served: 0, children_served: 0, family_zipcodes: 0, family_zipcodes_list: []}) }
    end
  end
end
