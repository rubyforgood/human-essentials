RSpec.describe "Annual Reports", type: :request do
  let(:organization) { create(:organization) }
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
