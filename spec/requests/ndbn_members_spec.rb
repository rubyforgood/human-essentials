require "rails_helper"

RSpec.describe "NDBNMembers", type: :request do
  describe "GET /index" do
    context "when user does not have role 'NDBN'" do
      it "redirects to the root path" do
        user = create(:user)
        sign_in user
        get ndbn_members_path

        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "when user has role 'NDBN'" do
      let(:user) { create(:ndbn_user) }

      it "renders the index page" do
        sign_in user
        get ndbn_members_path

        expect(response).to be_successful
      end

      it "displays the NDBN members and csv upload" do
        sign_in user
        get ndbn_members_path

        create(:ndbn_member, ndbn_member_id: "123", account_name: "A Baby Center")

        get ndbn_members_path
        html = Nokogiri::HTML(response.body)

        expect(html.css("h1").text).to eq("NDBN Member Upload")
        expect(html.css("input[type=file]").count).to eq(1)
        expect(html.css("button[type=submit]").count).to eq(1)

        expect(html.css("th").map(&:text)).to match_array(["NDBN Member Number", "NDBN Member Name"])
        expect(html.css("tbody tr td").map(&:text)).to match_array(["123", "A Baby Center"])
      end

      context "when user is also an organization admin" do
        it "is successful" do
          user.add_role(Role::ORG_ADMIN, user.organization)
          sign_in user

          get ndbn_members_path

          expect(response).to be_successful
        end
      end

      context "when user is also a super admin" do
        it "is successful" do
          user.add_role(Role::SUPER_ADMIN)
          sign_in user

          get ndbn_members_path

          expect(response).to be_successful
        end
      end

      context "when user is also partner" do
        it "is successful" do
          user.add_role(Role::PARTNER, user.organization)
          sign_in user

          get ndbn_members_path

          expect(response).to be_successful
        end
      end
    end
  end

  describe "POST /create" do
    context "when user has role 'NDBN'" do
      let(:user) { create(:ndbn_user) }

      before do
        sign_in user
      end

      it "updates the index contents" do
        params = {member_file: fixture_file_upload("spec/fixtures/ndbn-large-import.csv", "text/csv")}

        post ndbn_members_path, params: params
        expected_url = ndbn_members_path(organization_name: user.organization.short_name)

        expect(response).to redirect_to(expected_url)
        expect(flash[:notice]).to eq("NDBN Members have been updated!")

        get ndbn_members_path
        body = response.body

        expect(body).to include("A Baby Center")
        expect(body).to include("Covering Weld; United Way of Weld County")
      end

      it "shows flash error if nil file provided" do
        params = {member_file: nil}

        post ndbn_members_path, params: params

        expect(response).to be_redirect
        expect(flash[:error]).to include("CSV upload is required")
      end
    end
  end
end
