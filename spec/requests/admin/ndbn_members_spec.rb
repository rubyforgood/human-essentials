RSpec.describe "NDBNMembers", type: :request do
  let(:user) { create(:super_admin) }

  before do
    sign_in user
  end

  describe "GET /index" do
    it "renders the index page" do
      get admin_ndbn_members_path

      expect(response).to be_successful
    end

    it "displays the NDBN members and csv upload" do
      create(:ndbn_member, ndbn_member_id: "123", account_name: "A Baby Center")

      get admin_ndbn_members_path

      html = Nokogiri::HTML(response.body)

      expect(html.css("h1").text).to eq("NDBN Member Upload")
      expect(html.css("input[type=file]").count).to eq(1)
      expect(html.css("button[type=submit]").count).to eq(1)

      expect(html.css("th").map(&:text)).to match_array(["NDBN Member Number", "Member Name"])
      expect(html.css("tbody tr td").map(&:text)).to match_array(["123", "A Baby Center"])
    end
  end

  describe "POST /upload_csv" do
    it "updates the index contents" do
      params = {member_file: fixture_file_upload("spec/fixtures/ndbn-small-import.csv", "text/csv")}

      post upload_csv_admin_ndbn_members_path, params: params

      expect(response).to redirect_to(admin_ndbn_members_path)
      expect(flash[:notice]).to eq("NDBN Members have been updated!")

      get admin_ndbn_members_path
      body = response.body

      expect(body).to include("Other Spot")
      expect(body).to include("Pawnee")
      expect(body).to include("Amazing Place")
    end

    context "with invalid values" do
      it "shows flash error " do
        params = {member_file: nil}

        post upload_csv_admin_ndbn_members_path, params: params

        expect(response).to be_redirect
        expect(flash[:error]).to include("CSV upload is required.")
      end
    end
  end
end
