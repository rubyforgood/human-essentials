require "rails_helper"

RSpec.describe OrganizationsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  before do
    sign_in(@user)
  end

  describe "GET #edit" do
    subject { get :edit, params: default_params }

    it "is successful" do
      expect(subject).to be_successful
    end
  end

  describe "updating an existing organization" do
    subject { patch :update, params: default_params.merge(organization: { name: "Thunder Pants" }) }

    it "can update name" do
      expect(subject).to have_http_status(:redirect)

      @organization.reload
      expect(@organization.name).to eq "Thunder Pants"
    end
  end
end
