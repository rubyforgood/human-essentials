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
        refute page.has_content? 'Number of individuals'

        # Checking that the request page doesn't have these options
        visit partners_requests_path
        refute page.has_content? 'Make a request'
        refute page.has_content? 'Quantity'
        refute page.has_content? 'Specify the family and child you are requesting for'
        refute page.has_content? 'Number of individuals'
      end

      it "Double clicking submit for approval button does not result in the partner attemping to be approved twice" do
        click_on 'Profile'
        assert page.has_content? 'Uninvited'
        all('a', text: 'Update information').last.click

        fill_in 'Other agency type', with: 'Lorem'

        fill_in 'Executive director name', with: 'Lorem'
        fill_in 'Executive director phone', with: '8889990000'
        fill_in 'Executive director email', with: 'lorem@example.com'
        fill_in 'Primary contact phone', with: '8889990000'
        check 'No social media presence'

        click_on 'Update information'
        assert page.has_content? 'Details were successfully updated.'

        assert page.has_content? "Submit for approval"

        ferrum_double_click('form[action*="/partners/approval_request"] button')

        expect(page).to have_content("Pending approval")
        expect(page).not_to have_content("This partner has already requested approval.")
      end

      context 'AND they fill out the form and submit it' do
        before do
          click_on 'Profile'
          assert page.has_content? 'Uninvited'
          all('a', text: 'Update information').last.click

          fill_in 'Other agency type', with: 'Lorem'

          fill_in 'Executive director name', with: 'Lorem'
          fill_in 'Executive director phone', with: '8889990000'
          fill_in 'Executive director email', with: 'lorem@example.com'
          fill_in 'Primary contact phone', with: '8889990000'
          check 'No social media presence'

          click_on 'Update information'
          assert page.has_content? 'Details were successfully updated.'

          all('button', text: 'Submit for approval').last.click
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
            assert page.has_content? 'Number of individuals'
          end
        end
      end
    end
  end

  describe "request approval with invalid details" do
    let(:partner_user) { partner.primary_user }
    let(:partner) { FactoryBot.create(:partner) }

    before do
      partner.profile.update(website: '', facebook: '', twitter: '', instagram: '', no_social_media_presence: false)
      login_as(partner_user)
      visit partner_user_root_path
      click_on 'Profile'
      all('button', text: 'Submit for approval').last.click
    end

    it "should render an error message", :aggregate_failures do
      assert page.has_content? 'No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.'
    end
  end
end
