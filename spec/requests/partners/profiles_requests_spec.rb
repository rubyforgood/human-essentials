require "rails_helper"

RSpec.describe "/partners/profiles", type: :request do
  let(:partner) { create(:partner, name: "Partnerrific") }
  let(:partner_user) { partner.primary_user }

  before do
    sign_in(partner_user)
  end

  describe "GET #show" do
    it "displays the partner" do
      get partners_profile_path(partner)
      expect(response.body).to include("Partnerrific")
    end

    it "shows correct values for yes/no buttons" do
      partner.profile.update!(currently_provide_diapers: nil, form_990: false, income_verification: true)
      get partners_profile_path(partner)
      expect(response.body).to include("<dt>Current Providing Diapers</dt>\n      <dd>Unspecified</dd>")
      expect(response.body).to include("<dt>Form 990 Filed</dt>\n      <dd>No</dd>")
      expect(response.body).to include("<dt>Do You Verify The Income Of Your Clients</dt>\n      <dd>Yes</dd>")
    end
  end

  describe "GET #edit" do
    it "displays the partner" do
      get edit_partners_profile_path(partner)
      expect(response.body).to include("Partnerrific")
    end

    it "does not have default radio button value when value is nil" do
      partner.profile.update!(storage_space: nil)
      get edit_partners_profile_path(partner)
      expect(response.body).not_to include("type=\"radio\" value=\"true\" checked=\"checked\" name=\"partner[profile][storage_space]\" id=\"partner_profile_storage_space_true\" />")
      expect(response.body).not_to include("type=\"radio\" value=\"false\" checked=\"checked\" name=\"partner[profile][storage_space]\" id=\"partner_profile_storage_space_false\"")
    end

    it "has \"Yes\" radio button value when value is true" do
      partner.profile.update!(storage_space: true)
      get edit_partners_profile_path(partner)
      expect(response.body).to include("type=\"radio\" value=\"true\" checked=\"checked\" name=\"partner[profile][storage_space]\" id=\"partner_profile_storage_space_true\" />")
      expect(response.body).not_to include("type=\"radio\" value=\"false\" checked=\"checked\" name=\"partner[profile][storage_space]\" id=\"partner_profile_storage_space_false\"")
    end

    it "has \"No\" radio button value when value is false" do
      partner.profile.update!(storage_space: false)
      get edit_partners_profile_path(partner)
      expect(response.body).not_to include("type=\"radio\" value=\"true\" checked=\"checked\" name=\"partner[profile][storage_space]\" id=\"partner_profile_storage_space_true\" />")
      expect(response.body).to include("type=\"radio\" value=\"false\" checked=\"checked\" name=\"partner[profile][storage_space]\" id=\"partner_profile_storage_space_false\"")
    end
  end

  describe "PUT #update" do
    it "updates the partner and profile" do
      partner.profile.update!(address1: "123 Main St.", address2: "New York, New York")
      put partners_profile_path(partner,
        partner: {name: "Partnerdude", profile: {address1: "456 Main St.", address2: "Washington, DC"}})
      expect(partner.reload.name).to eq("Partnerdude")
      expect(partner.profile.reload.address1).to eq("456 Main St.")
      expect(partner.profile.address2).to eq("Washington, DC")
      expect(response).to redirect_to(partners_profile_path)
    end

    context "with no social media" do
      it "shows an error" do
        put partners_profile_path(partner,
          partner: {name: "Partnerdude", profile: {website: "", no_social_media: false}})
        expect(response).not_to redirect_to(anything)
        expect(response.body).to include("No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.")
      end
    end

    context "when updating an existing value to a blank value" do
      before do
        partner.profile.update!(city: "")
        put partners_profile_path(partner,
          partner: {name: "Partnerdude", profile: {city: "", website: "N/A"}})
      end

      it "updates the partner profile attribute to a blank value" do
        expect(partner.profile.reload.city).to eq ""
      end

      it "does not update other partner profile attributes to blank" do
        expect(partner.profile.reload.address2).to be_nil
      end

      it "does store N/A in the database" do
        expect(partner.profile.reload.website).to eq "N/A"
      end
    end
  end
end
