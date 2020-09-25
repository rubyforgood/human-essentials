require 'csv'
require 'rails_helper'

RSpec.describe "DataExports", type: :request do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
      allow_any_instance_of(Partner).to receive(:contact_person) { Hash.new }
    end

    describe "GET #csv" do
      it "return empty data when no type is passed" do
        get csv_path(default_params, format: "csv")
        expect(response.parsed_body).to be_empty
      end

      it "returns data when a valid type is requested" do
        DataExport::SUPPORTED_TYPES.each do |type|
          get csv_path(default_params.merge(type: type, format: "csv"))
          expect(response.parsed_body).to_not be_empty
        end
      end
    end
  end
end
