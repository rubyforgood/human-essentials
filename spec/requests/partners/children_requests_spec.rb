RSpec.describe "/partners/children", type: :request do
  let(:partner_user) { partner.primary_user }
  let(:partner) { create(:partner) }
  let(:family) { create(:partners_family, partner: partner) }
  let(:item1) { create(:item, organization: partner.organization) }
  let(:item2) { create(:item, organization: partner.organization) }
  let!(:child1) do
    create(:partners_child,
      first_name: "John",
      last_name: "Smith",
      date_of_birth: "2019-01-01",
      gender: "Male",
      child_lives_with: %w[mother grandfather],
      race: "Other",
      agency_child_id: "Agency McAgence",
      health_insurance: "Private insurance",
      comments: "Some comment",
      requested_item_ids: nil,
      active: true,
      archived: false,
      family: family)
  end
  let!(:child2) do
    create(:partners_child,
      first_name: "Jane",
      last_name: "Smith",
      date_of_birth: "2018-01-01",
      gender: "Female",
      child_lives_with: %w[father],
      race: "Hispanic",
      agency_child_id: "Agency McAgence",
      health_insurance: "Private insurance",
      comments: "Some comment",
      active: true,
      archived: false,
      requested_item_ids: [item1.id, item2.id],
      family: family)
  end

  describe "GET #index" do
    before do
      sign_in(partner_user)
    end

    it "should render without any issues" do
      get partners_children_path
      expect(response).to render_template(:index)
    end

    it "should export CSV" do
      headers = {"Accept" => "text/csv", "Content-Type" => "text/csv"}
      get partners_children_path, headers: headers
      csv = <<~CSV
        id,first_name,last_name,date_of_birth,gender,child_lives_with,race,agency_child_id,health_insurance,comments,created_at,updated_at,family_id,requested_item_ids,active,archived
        #{child1.id},John,Smith,2019-01-01,Male,"mother,grandfather",Other,Agency McAgence,Private insurance,Some comment,#{child1.created_at},#{child1.updated_at},#{family.id},"",true,false
        #{child2.id},Jane,Smith,2018-01-01,Female,father,Hispanic,Agency McAgence,Private insurance,Some comment,#{child2.created_at},#{child2.updated_at},#{family.id},"#{item1.id},#{item2.id}",true,false
      CSV
      expect(response.body).to eq(csv)
    end
  end
end
