require 'csv'

RSpec.describe DataExportsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #csv" do
      it "return empty data when no type is passed" do
        get :csv, format: "csv", params: default_params
        expect(response.parsed_body).to be_empty
      end

      it "returns data when a valid type is requested" do
        DataExport::SUPPORTED_TYPES.each do |type|
          get :csv, format: "csv", params: default_params.merge(type: type)
          expect(response.parsed_body).to_not be_empty
        end
      end
    end
  end
end
