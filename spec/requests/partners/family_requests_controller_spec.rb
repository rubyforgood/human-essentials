RSpec.describe Partners::FamilyRequestsController, type: :request do
  let(:partner) { create(:partner) }
  let(:params) do
    children.each_with_object({}) do |child, hash|
      hash["child-#{child.id}"] = true
    end
  end
  let(:family) { create(:partners_family, partner_id: partner.id) }
  let!(:children) { FactoryBot.create_list(:partners_child, 3, family: family) }
  let(:partner_user) { partner.primary_user }

  before { sign_in(partner_user) }

  describe 'GET #new' do
    subject { get new_partners_family_request_path }

    it "does not allow deactivated partners" do
      partner.update!(status: :deactivated)

      expect(subject).to redirect_to(partners_requests_path)
    end

    it "does not allow partners not verified" do
      partner.update!(status: :uninvited)

      expect(subject).to redirect_to(partners_requests_path)
    end
  end

  describe 'POST #create' do
    before do
      # Set one child as deactivated and the other as active but
      # without a item_needed_diaperid
      children[0].update(active: false)
      children[1].update(requested_item_ids: [])
    end
    subject { post partners_family_requests_path, params: params }

    it "does not allow deactivated partners" do
      partner.update!(status: :deactivated)

      expect(subject).to redirect_to(partners_requests_path)
    end

    it "does not allow partners not verified" do
      partner.update!(status: :uninvited)

      expect(subject).to redirect_to(partners_requests_path)
    end

    it "submits the request" do
      partner.update!(status: :approved)

      subject

      expect(response.request.flash[:notice]).to eql "Requested items successfully!"
    end
  end
end
