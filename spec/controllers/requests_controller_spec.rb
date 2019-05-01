RSpec.describe RequestsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject { get :index, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:request, organization: @organization, comments: "comments", request_items: nil)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    context "start a request" do
      let!(:request) { create(:request) }
      let(:request_id) { request.id }
      let(:params) { default_params.merge(id: request_id) }

      before { post :start, params: params }

      it "change request status to started" do
        expect(request.reload).to be_status_started
      end
      it "redirect to new distribution path" do
        expect(response).to redirect_to(new_distribution_path(request_id: request_id))
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:request) }

    include_examples "requiring authorization"
  end
end
