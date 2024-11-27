RSpec.describe "Approval process for partners", type: :system, js: true do
  describe 'filling in organization details and requesting for approval' do
    let(:partner_user) { partner.primary_user }
    let!(:partner) { FactoryBot.create(:partner) }

    context 'GIVEN a partner user is new and wants to request approval' do
      before do
        login_as(partner_user)
        visit partner_user_root_path
      end

      it 'should not allow them to make requests on the dashboard or the requests page' do
        # Checking that the dashboard doesn't have these options
        refute page.has_content? 'Make a request'
        refute page.has_content? 'Quantity'
        refute page.has_content? 'Specify the family and child you are requesting for'
        refute page.has_content? '# of Individuals'

        # Checking that the request page doesn't have these options
        visit partners_requests_path
        refute page.has_content? 'Make a request'
        refute page.has_content? 'Quantity'
        refute page.has_content? 'Specify the family and child you are requesting for'
        refute page.has_content? '# of Individuals'
      end

      context 'AND they fill out the form and submit it' do
        before do
          click_on 'My Organization'
          assert page.has_content? 'Uninvited'
          click_on 'Update Information'

          fill_in 'Other Agency Type', with: 'Lorem'

          fill_in 'Executive Director Name', with: 'Lorem'
          fill_in 'Executive Director Phone', with: '8889990000'
          fill_in 'Executive Director Email', with: 'lorem@example.com'
          fill_in 'Primary Contact Phone', with: '8889990000'
          check 'No Social Media Presence'

          click_on 'Update Information'
          assert page.has_content? 'Details were successfully updated.'

          find_link(text: 'Submit for Approval').click
          assert page.has_content? 'You have submitted your details for approval.'
          assert page.has_content? 'Awaiting Review'
        end

        context 'THEN the organization approves them' do
          before do
            # Emulate approving the partner using the service object
            PartnerApprovalService.new(partner: partner.reload).call
            # Revisit the profile page
            visit partners_profile_path
          end

          it 'should show that they have been approved and able to make requests', :aggregate_failures do
            assert page.has_content? 'Approved'

            visit partners_requests_path
            assert page.has_content? 'Make a request'
            assert page.has_content? 'Quantity'
            assert page.has_content? 'Specify the family and child you are requesting for'
            assert page.has_content? '# of Individuals'
          end
        end
      end
    end
  end

  describe "request approval with invalid details" do
    let(:partner_user) { partner.primary_user }
    let(:partner) { FactoryBot.create(:partner) }

    before do
      partner.profile.update(website: '', facebook: '', twitter: '', instagram: '', no_social_media_presence: false, partner_status: 'pending')
      login_as(partner_user)
      visit partner_user_root_path
      click_on 'My Organization'
      click_on 'Submit for Approval'
    end

    it "should render an error message", :aggregate_failures do
      assert page.has_content? 'No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.'
    end
  end
end
