require "rails_helper"

RSpec.describe "/partners/profiles", type: :request do
  describe "basic" do
    let(:organization) { create(:organization, name: "Favourite Bank", partner_form_fields: [])}

    let(:partner) { create(:partner, name: "Partnerrific", organization: organization) }
    let(:partner_user) { partner.primary_user }
    before do
      sign_in(partner_user)
    end

    describe "on show" do
      it "displays the partner area served entry if there are no partials specified for the organization" do
        get partners_profile_path(partner)
        expect(response.body).to include("Area Served")
      end

      it "handles empty county list" do
        get partners_profile_path(partner)
        expect(response.body).to include("No County Specified")
      end

    end

    describe "GET #edit" do
      it "displays the partner area served entry if there are no partials specified for the organization" do
        get edit_partners_profile_path(partner)
        expect(response.body).to include("Area Served")
      end

    end

    describe "PUT #update" do

      xit "updates the county info" do
        #TODO write update county info test
=begin
        partner.profile.update!(address1: "123 Main St.", address2: "New York, New York")
        put partners_profile_path(partner,
          partner: {name: "Partnerdude"},
          profile: {address1: "456 Main St.", address2: "Washington, DC"})
        expect(partner.reload.name).to eq("Partnerdude")
        expect(partner.profile.reload.address1).to eq("456 Main St.")
        expect(partner.profile.address2).to eq("Washington, DC")
        expect(response).to redirect_to(partners_profile_path)
=end
      end
    end
  end

  describe "partial (area served) absence when only other partials specified" do
    let(:organization) { create(:organization, name: "Bank of Favourville", partner_form_fields: ["media_information"])}
    let(:partner) { create(:partner, name: "Partnertonic", organization: organization) }
    let(:partner_user) { partner.primary_user }
    before do
      sign_in(partner_user)
    end
    describe "on show" do
      it "does not display the client share if only other partials are specified" do
        partner.organization = organization
        get partners_profile_path(partner)
        expect(response.body).to_not include("Area Served")
      end


    end
    describe "on edit" do
      it "does not display the client share if only other partials are specified" do
        partner.organization = organization
        get edit_partners_profile_path(partner)
        expect(response.body).to_not include("Area Served")
      end
    end
  end


  describe "partial (client_share) presence when that partial specified" do
    let(:organization) { create(:organization, name: "3rd National Bank of Favour", partner_form_fields: ["area_served"])}
    let(:partner) { create(:partner, name: "Partnerlicious", organization: organization) }
    let(:partner_user) { partner.primary_user }
    before do
      sign_in(partner_user)
    end
    describe "on show" do
      it "displays the area served if specified" do
        partner.organization = organization
        get partners_profile_path(partner)
        expect(response.body).to include("Area Served")
      end
      it "handles empty county list" do
        get partners_profile_path(partner)
        expect(response.body).to include("No County Specified")
      end
      describe "full_county_list" do
        let(:county_1) {create(:county, name: "First County")}
        let(:county_2) {create(:county, name: "Second County")}
        let!(:pc_1) {create(:partner_county, partner: partner, county: county_1, client_share: 70)}
        let!(:pc_2) {create(:partner_county, partner: partner, county: county_2, client_share: 30)}
        it "displays the counties" do
          get partners_profile_path(partner)
          expect(response.body).to include(pc_1.county.name)
          expect(response.body).to include(pc_2.county.name)
          expect(response.body).not_to include ("No County Specified")
        end
      end
    end
    describe "on edit" do
      it "displays the area served if specified" do
        partner.organization = organization
        get edit_partners_profile_path(partner)
        expect(response.body).to include("Area Served")
      end
      describe "full_county_list" do
        let(:county_1) {create(:county, name: "First County")}
        let(:county_2) {create(:county, name: "Second County")}
        let!(:pc_1) {create(:partner_county, partner: partner, county: county_1, client_share: 70)}
        let!(:pc_2) {create(:partner_county, partner: partner, county: county_2, client_share: 30)}
        before do
          get edit_partners_profile_path(partner)
        end
        it "displays the counties" do
          expect(response.body).to include(pc_1.county.name)
          expect(response.body).to include(pc_2.county.name)
          expect(response.body).not_to include ("No County Specified")
        end
        it "has the right total" do
          expect(response.body).to include "Total is: 100 %"
        end
      end
    end
  end


end

