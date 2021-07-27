require "rails_helper"

RSpec.describe Partners::FamilyRequestsController, type: :request do
  let(:partner) { create(:partner) }
  let(:params) { { 'child-1' => true, 'child-2' => true, 'child-3' => true } }
  let(:partners_partner) { Partners::Partner.find_by(diaper_partner_id: partner.id) }
  let(:family) { create(:partners_family, partner_id: partners_partner.id) }
  let(:children) { FactoryBot.create_list(:partners_child, 3, family: family) }
  let(:partner_user) { partners_partner.primary_user }

  before { sign_in(partner_user, scope: :partner_user) }

  describe 'GET #new' do
    subject { get new_partners_family_request_path }

    it "does not allow deactivated partners" do
      partners_partner.update!(status_in_diaper_base: :deactivated)

      expect(subject).to redirect_to(partners_requests_path)
    end

    it "does not allow partners not verified" do
      partners_partner.update!(partner_status: :pending)

      expect(subject).to redirect_to(partners_requests_path)
    end
  end

  describe 'POST #create' do
    before do
      # Set one child as deactivated and the other as active but
      # without a item_needed_diaperid
      children[0].update(active: false)
      children[1].update(item_needed_diaperid: nil)
    end
    subject { post partners_family_requests_path, params: params }

    it "does not allow deactivated partners" do
      partners_partner.update!(status_in_diaper_base: :deactivated)

      expect(subject).to redirect_to(partners_requests_path)
    end

    it "does not allow partners not verified" do
      partners_partner.update!(partner_status: :pending)

      expect(subject).to redirect_to(partners_requests_path)
    end

    it "submits the request" do
      partners_partner.update!(partner_status: :verified)

      subject

      expect(response.request.flash[:notice]).to eql "Requested items successfully!"
    end
  end
end
