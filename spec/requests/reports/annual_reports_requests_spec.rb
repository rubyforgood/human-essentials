RSpec.describe "Annual Reports", type: :request do
  let(:organization) { create(:organization, :created_at_2006) }
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

      it "displays the first day of the following year as the date when the report will be available" do
        travel_to Time.zone.local(2026, 12, 31)

        get reports_annual_reports_path(default_params)

        expect(response.body).to include("available on January 1, 2027")
      end

      it "offers the range export when there is at least one complete year" do
        get reports_annual_reports_path(default_params)

        expect(response.body).to include("Export Yearly Reports")
      end

      it "does not offer the range export when no year is complete yet" do
        # A bank that started this year has nothing complete to export.
        organization.update!(created_at: Time.current)
        organization.donations.destroy_all
        organization.purchases.destroy_all

        get reports_annual_reports_path(default_params)

        expect(response.body).not_to include("Export Yearly Reports")
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

    describe "GET /range" do
      it "returns AnnualReports within given range" do
        get range_reports_annual_reports_path(year_start: 2016, year_end: 2018, format: :csv)
        expect(response.body).to include("2016")
        expect(response.body).to include("2017")
        expect(response.body).to include("2018")
      end

      it "returns URL error if years are not valid format" do
        expect { get range_reports_annual_reports_path(year_start: 'test', year_end: 'test', format: :csv) }
          .to raise_error(ActionController::UrlGenerationError)
      end

      it "does not start earlier than the organization's earliest_reporting_year" do
        get range_reports_annual_reports_path(year_start: 2004, year_end: 2008, format: :csv)
        # the organization was created in 2006 (created_at_2006)
        # so the below years should not be in the output
        expect(response.body).not_to include("2004")
        expect(response.body).not_to include("2005")
      end

      it "orders the years in ascending order" do
        get range_reports_annual_reports_path(year_start: 2018, year_end: 2016, format: :csv)
        csv_array = response.body.split("\n")
        # csv_array[0] is the header row
        expect(csv_array[1]).to include("2016")
        expect(csv_array[2]).to include("2017")
        expect(csv_array[3]).to include("2018")
      end

      it "does not include the current year, which is still in progress" do
        get range_reports_annual_reports_path(year_start: Time.current.year - 1, year_end: Time.current.year, format: :csv)
        years = response.body.split("\n").drop(1).map { |row| row.split(",").first }

        expect(years).to include((Time.current.year - 1).to_s)
        expect(years).not_to include(Time.current.year.to_s)
      end

      context "when the requested range falls entirely outside the reportable years" do
        it "is not found for a range before the organization existed" do
          get range_reports_annual_reports_path(year_start: 1990, year_end: 1995, format: :csv)

          expect(response).to have_http_status(:not_found)
        end

        it "is not found for a range in the future" do
          get range_reports_annual_reports_path(year_start: Time.current.year + 4,
            year_end: Time.current.year + 9, format: :csv)

          expect(response).to have_http_status(:not_found)
        end

        it "is not found for a reversed range in the future" do
          get range_reports_annual_reports_path(year_start: Time.current.year + 9,
            year_end: Time.current.year + 4, format: :csv)

          expect(response).to have_http_status(:not_found)
        end

        it "does not create annual reports for years outside the range" do
          expect {
            get range_reports_annual_reports_path(year_start: 1990, year_end: 1995, format: :csv)
          }.not_to change { AnnualReport.count }
        end
      end
    end
  end
end
