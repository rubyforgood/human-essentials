RSpec.describe "Coworking invitations", type: :system, js: true do
  describe 'inviting coworker as a partner user' do
    let(:partner_user) { partner.primary_partner_user }
    let!(:partner) { FactoryBot.create(:partner) }

    context 'GIVEN a partner user is permitted to make a request' do
      before do
        login_as(partner_user, scope: :partner_user)
        visit new_partners_request_path
      end

      it 'should do' do
        magic_test
      end
    end
  end
end


