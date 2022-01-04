require 'rails_helper'

RSpec.describe "Admin::Helps", type: :request do
  context "while signed in as a super admin" do
    before do
      sign_in(@super_admin_no_org)
    end

    it "allows a user to load the help page" do
      get admin_help_path
      expect(response).to be_successful
    end
  end
end
