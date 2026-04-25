RSpec.describe "Annual Reports", type: :request do
  let(:organization) { create(:organization, created_at: Time.zone.local(2006, 1, 1)) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  let(:default_params) do
    { year: 2018 }
  end

  context "While signed in" do
    before do
      sign_in(user)
    end

    describe "GET /index" do
      it "returns http success" do
        get reports_annual_reports_path(default_params)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /show" do
      it "returns http success" do
        expect(AnnualReport.count).to eq(0)
        get reports_annual_report_path(default_params)
        expect(response).to have_http_status(:success)
        expect(AnnualReport.count).to eq(1)
        expect(AnnualReport.last.year).to eq(2018)
        expect(AnnualReport.last.organization_id).to eq(organization.id)
      end

      it "retrieves and uses the existing report if it exists" do
        old_time = 1.year.ago
        report = AnnualReport.create!(year: 2018,
                                      organization_id: organization.id,
                                      updated_at: old_time,
                                      all_reports: [{ name: 'dummy', entries: [{ dummy: 'text' }] }])
        get reports_annual_report_path(default_params)
        expect(response).to have_http_status(:success)
        expect(AnnualReport.count).to eq(1)
        expect(report.reload.updated_at).to be_within(1.second).of(old_time)
      end

      it "retrieves and updated the existing report if it exists" do
        report = AnnualReport.create!(year: 2018, organization_id: organization.id)
        expect(report.all_reports).to be_nil
        get reports_annual_report_path(default_params)
        expect(response).to have_http_status(:success)
        expect(AnnualReport.count).to eq(1)
        expect(report.reload.all_reports).not_to be_nil
      end

      it "returns not found if the year params is not number" do
        get reports_annual_report_path({ year: 'invalid' })
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /range" do
      context "with valid year range" do
        it "returns http success and generates a CSV with the correct year ranges" do
          get range_reports_annual_reports_path(year_start: 2016, year_end: 2018, format: :csv)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("2016")
          expect(response.body).to include("2017")
          expect(response.body).to include("2018")
        end

        it "returns correct data given columns are not at parity between years" do
          # Some years may have columns that do not exist in other years, simulate the
          # situation with "New Field" that only exists in 2017, but not 2016
          shared_entries = { "Total Distributed" => 100, "Total Donors" => 5 }
          extra_entries = { "Total Distributed" => 200, "Total Donors" => 8, "New Field" => 42 }

          report_2016 = instance_double(AnnualReport,
                                        "[]": nil,
                                        all_reports: [{ "entries" => shared_entries }])
          report_2017 = instance_double(AnnualReport,
                                        "[]": nil,
                                        all_reports: [{ "entries" => extra_entries }])

          allow(report_2016).to receive(:[]).with("year").and_return(2016)
          allow(report_2017).to receive(:[]).with("year").and_return(2017)

          allow(Reports).to receive(:retrieve_report)
            .with(hash_including(year: 2016)).and_return(report_2016)
          allow(Reports).to receive(:retrieve_report)
            .with(hash_including(year: 2017)).and_return(report_2017)

          get range_reports_annual_reports_path(year_start: 2016, year_end: 2017, format: :csv)

          csv = CSV.parse(response.body, headers: true)

          expect(csv&.headers).to include("Year", "Total Distributed", "Total Donors", "New Field")

          row_2016 = csv&.find { |r| r["Year"] == "2016" }
          row_2017 = csv&.find { |r| r["Year"] == "2017" }

          expect(row_2016["New Field"]).to be_nil
          expect(row_2017["New Field"]).to eq("42")
          expect(row_2017["Total Distributed"]).to eq("200")
        end
      end

      context "invalid year ranges given" do
        it "should raise a URL error" do
          expect { get range_reports_annual_reports_path(year_start: 'test', year_end: 'test', format: :csv) }
            .to raise_error(ActionController::UrlGenerationError)
        end

        it "should redirect and show an error message if end year is less than start year" do
          get range_reports_annual_reports_path(year_start: 2018, year_end: 2016, format: :csv)
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("End year must be greater than or equal to start year.")
        end
      end
    end

    describe 'POST /recalculate' do
      it "recalculates new reports" do
        expect(AnnualReport.count).to eq(0)
        post recalculate_reports_annual_report_path(default_params)
        expect(response).to have_http_status(:found)
        expect(AnnualReport.count).to eq(1)
        expect(AnnualReport.last.year).to eq(2018)
        expect(AnnualReport.last.organization_id).to eq(organization.id)
      end

      it 'recalculates an existing report' do
        old_time = 1.year.ago
        report = AnnualReport.create!(year: 2018,
                                      organization_id: organization.id,
                                      updated_at: old_time,
                                      all_reports: [{ name: 'dummy', entries: [{ dummy: 'text' }] }])
        post recalculate_reports_annual_report_path(default_params)
        expect(response).to have_http_status(:found)
        expect(AnnualReport.count).to eq(1)
        expect(report.reload.updated_at).not_to be_within(1.second).of(old_time)
      end
    end
  end
end
