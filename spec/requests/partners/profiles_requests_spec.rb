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
  end

  describe "GET #edit" do
    it "displays the partner" do
      get edit_partners_profile_path(partner)
      expect(response.body).to include("Partnerrific")
    end
  end

  describe "PUT #update" do
    it "updates the partner and profile" do
      partner.profile.update!(address1: "123 Main St.", address2: "New York, New York")
      put partners_profile_path(partner,
        partner: {name: "Partnerdude"},
        profile: {address1: "456 Main St.", address2: "Washington, DC"})
      expect(partner.reload.name).to eq("Partnerdude")
      expect(partner.profile.reload.address1).to eq("456 Main St.")
      expect(partner.profile.address2).to eq("Washington, DC")
      expect(response).to redirect_to(partners_profile_path)
    end
  end
end
