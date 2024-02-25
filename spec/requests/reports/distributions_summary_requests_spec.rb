require "rails_helper"

RSpec.describe "Distributions", type: :request do
  context "while signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      it "shows a list of recent distributions" do
        get reports_distributions_summary_path(@user.organization)
        expect(response.body).to include("Recent distributions")
      end
    end
  end

  context "while not signed in" do
    describe "GET #index" do
      it "redirects user to sign in page" do
        get reports_distributions_summary_path(@user.organization)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
