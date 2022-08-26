require "rails_helper"

RSpec.describe "/partners/users", type: :request do
  let(:partner) { create(:partner) }
  let(:partner_user) { Partners::Partner.find_by(partner_id: partner.id).primary_user }

  before do
    sign_in(partner_user)
  end
end
