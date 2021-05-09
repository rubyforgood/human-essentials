RSpec.describe "Approval process for partners", type: :system, js: true do
  describe 'filling in organization details and requesting for approval' do
    let(:partner_user) { partner.primary_partner_user }
    let!(:partner) { FactoryBot.create(:partner) }

    context 'GIVEN a partner user is new and wants to request approval' do
      before do
        login_as(partner_user, scope: :partner_user)
        visit partner_user_root_path
      end

      it 'should not allow them to make requests on the dashboard or the requests page' do
        # Checking that the dashboard doesn't have these options
        refute page.has_content? 'Request Essentials'
        refute page.has_content? 'Create New Bulk Essentials Request'
        refute page.has_content? 'Create New Family Essentials Request'
        refute page.has_content? 'Create New Individuals Essentials Request'

        # Checking that the request page doesn't have these options
        visit partners_requests_path
        refute page.has_content? 'Request Essentials'
        refute page.has_content? 'Create New Bulk Essentials Request'
        refute page.has_content? 'Create New Family Essentials Request'
        refute page.has_content? 'Create New Individuals Essentials Request'
      end

      context 'AND they fill out the form and submit it' do
        before do
          click_on 'My Organization'
          assert page.has_content? 'pending'
          click_on 'Update Information'

          fill_in 'Other Agency Type', with: 'Lorem'

          fill_in 'Executive Director Name', with: 'Lorem'
          fill_in 'Executive Director Phone', with: '8889990000'
          fill_in 'Executive Director Email', with: 'lorem@example.com'
          fill_in 'Program Contact Phone', with: '8889990000'

          click_on 'Update Information'
          assert page.has_content? 'Details were successfully updated.'

          find_link(text: 'Submit for Approval').click
          assert page.has_content? 'You have submitted your details for approval.'
          assert page.has_content? 'submitted'
        end

        context 'THEN the organization approves them' do
          before do
            # Emulate approving the partner using the service object
            PartnerApprovalService.new(partner: partner.reload).call
            # Revisit the profile page
            visit partners_profile_path
          end

          it 'should show that they have been approved and able to make requests' do
            assert page.has_content? 'verified'

            visit partners_requests_path
            assert page.has_content? 'Request Essentials'
            assert page.has_content? 'Create New Bulk Essentials Request'
            assert page.has_content? 'Create New Family Essentials Request'
            assert page.has_content? 'Create New Individuals Essentials Request'
          end
        end
      end
    end
  end
end
