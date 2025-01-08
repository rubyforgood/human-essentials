RSpec.describe "/partners/family", type: :request do
  let(:partner_user) { partner.primary_user }
  let(:partner) { create(:partner) }
  let!(:family1) do
    create(:partners_family,
      guardian_first_name: "John",
      guardian_last_name: "Smith",
      guardian_zip_code: "90210",
      guardian_county: "Franklin",
      guardian_phone: "416-555-2345",
      case_manager: "Jane Smith",
      home_adult_count: 2,
      home_child_count: 3,
      home_young_child_count: 1,
      sources_of_income: %w[SSI TANF],
      guardian_employed: true,
      guardian_employment_type: "Part-time",
      guardian_monthly_pay: 4,
      guardian_health_insurance: "Medicaid",
      comments: "Some comment",
      military: false,
      partner: partner)
  end

  let!(:family2) do
    create(:partners_family,
      guardian_first_name: "Mark",
      guardian_last_name: "Smith",
      guardian_zip_code: "90210",
      guardian_county: "Jefferson",
      guardian_phone: "416-555-0987",
      case_manager: "Jane Smith",
      home_adult_count: 1,
      home_child_count: 2,
      home_young_child_count: 2,
      sources_of_income: %w[TANF],
      guardian_employed: false,
      guardian_employment_type: "Part-time",
      guardian_monthly_pay: 4,
      guardian_health_insurance: "Medicaid",
      comments: "Some comment 2",
      military: true,
      partner: partner,
      archived: true)
  end

  describe "GET #index" do
    before do
      sign_in(partner_user)
    end

    it "should render without any issues and display unarchived families by default" do
      get partners_families_path
      expect(response).to render_template(:index)
      expect(assigns[:families].count).to eq(1)
      expect(assigns[:families].pluck(:archived)).to all(be(false))
    end

    it "should render without any issues and present all families" do
      get partners_families_path, params: {"filterrific" => {"include_archived" => "1"}}
      expect(response).to render_template(:index)
      expect(assigns[:families].count).to eq(2)
    end

    it "should export CSV" do
      headers = {"Accept" => "text/csv", "Content-Type" => "text/csv"}
      params = {"filterrific" => {"search_guardian_names" => "", "search_agency_guardians" => "", "include_archived" => "1"}}
      get partners_families_path, headers: headers, params: params
      csv = <<~CSV
        id,guardian_first_name,guardian_last_name,guardian_zip_code,guardian_county,guardian_phone,case_manager,home_adult_count,home_child_count,home_young_child_count,sources_of_income,guardian_employed,guardian_employment_type,guardian_monthly_pay,guardian_health_insurance,comments,created_at,updated_at,partner_id,military,archived
        #{family1.id},John,Smith,90210,Franklin,416-555-2345,Jane Smith,2,3,1,"SSI,TANF",true,Part-time,4.0,Medicaid,Some comment,#{family1.created_at},#{family1.updated_at},#{partner.id},false,false
        #{family2.id},Mark,Smith,90210,Jefferson,416-555-0987,Jane Smith,1,2,2,TANF,false,Part-time,4.0,Medicaid,Some comment 2,#{family2.created_at},#{family2.updated_at},#{partner.id},true,true
      CSV
      expect(response.body).to eq(csv)
    end
  end
end
