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
#  enable_quantity_based_requests :boolean          default(TRUE), not null
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
#  instagram                      :string
#  more_docs_required             :string
#  name                           :string
#  new_client_times               :string
#  no_social_media_presence       :boolean
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

  describe "social media info validation for partners" do
    context "no social media presence and the checkbox isn't checked" do
      let(:partner) { FactoryBot.build(:partner_profile, website: "", twitter: "", facebook: "", instagram: "", no_social_media_presence: false) }

      it "should not be valid" do
        expect(partner.valid?).to eq(false)
      end
    end

    context "no social media presence and the checkbox is checked" do
      let(:partner) { FactoryBot.build(:partner_profile, website: "", twitter: "", facebook: "", instagram: "", no_social_media_presence: true) }

      it "should be valid" do
        expect(partner.valid?).to eq(true)
      end
    end

    context "has social media presence and the checkbox is unchecked" do
      let(:partner) { FactoryBot.build(:partner_profile, no_social_media_presence: false) }

      it "with just a website it should be valid" do
        partner.update(website: "some website URL", twitter: "", facebook: "", instagram: "")
        expect(partner.valid?).to eq(true)
      end

      it "with just twitter it should be valid" do
        partner.update(website: "", twitter: "some twitter URL", facebook: "", instagram: "")
        expect(partner.valid?).to eq(true)
      end

      it "with just facebook it should be valid" do
        partner.update(website: "", twitter: "", facebook: "some facebook URL", instagram: "")
        expect(partner.valid?).to eq(true)
      end

      it "with just instagram it should be valid" do
        partner.update(website: "", twitter: "", facebook: "", instagram: "some instagram URL")
        expect(partner.valid?).to eq(true)
      end

      it "with every social media option it should be valid" do
        partner.update(website: "some website URL", twitter: "some twitter URL", facebook: "some facebook URL", instagram: "some instagram URL")
        expect(partner.valid?).to eq(true)
      end
    end
  end
end
