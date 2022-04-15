require "rails_helper"

RSpec.describe "/partners/distributions", type: :request do
  describe "GET #index" do
    subject { -> { get partners_distributions_path } }
    let(:partner_user) { Partners::Partner.find_by(diaper_partner_id: partner.id).primary_user }
    let(:partner) { create(:partner) }

    before do
      sign_in(partner_user, scope: :partner_user)
    end

    it "should render without any issues" do
      subject.call
      expect(response).to render_template(:index)
    end
  end
end
