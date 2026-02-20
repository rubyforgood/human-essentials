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

      it "Double clicking submit for approval button does not result in the partner attemping to be approved twice" do
        click_on 'My Profile'
        assert page.has_content? 'Uninvited'
        all('a', text: 'Update Information').last.click

        fill_in 'Other Agency Type', with: 'Lorem'

        fill_in 'Executive Director Name', with: 'Lorem'
        fill_in 'Executive Director Phone', with: '8889990000'
        fill_in 'Executive Director Email', with: 'lorem@example.com'
        fill_in 'Primary Contact Phone', with: '8889990000'
        select "Basic Needs Bank", from: "Agency Type"
        within "#agency_information" do
          fill_in 'Address (line 1)', with: '1234 Main St'
          fill_in 'City', with: 'Anytown'
          fill_in 'State', with: 'CA'
          fill_in 'Zip', with: '12345'
        end
        check 'No Social Media Presence'
        fill_in 'Program Name(s)', with: 'Test Program'
        fill_in 'Program Description', with: 'This is a test program description.'

        click_on 'Update Information'
        assert page.has_content? 'Details were successfully updated.'

        assert page.has_content? "Submit for Approval"

        ferrum_double_click('form[action*="/partners/approval_request"] .btn.btn-success')

        expect(page).to have_content("Pending Approval")
        expect(page).not_to have_content("This partner has already requested approval.")
      end

      context 'AND they fill out the form and submit it' do
        before do
          click_on 'My Profile'
          assert page.has_content? 'Uninvited'
          all('a', text: 'Update Information').last.click

          fill_in 'Other Agency Type', with: 'Lorem'

          fill_in 'Executive Director Name', with: 'Lorem'
          fill_in 'Executive Director Phone', with: '8889990000'
          fill_in 'Executive Director Email', with: 'lorem@example.com'
          within "#agency_information" do
            fill_in 'Address (line 1)', with: '1234 Main St'
            fill_in 'City', with: 'Anytown'
            fill_in 'State', with: 'CA'
            fill_in 'Zip', with: '12345'
          end
          fill_in 'Primary Contact Phone', with: '8889990000'
          select "Basic Needs Bank", from: "Agency Type"
          fill_in 'Program Name(s)', with: 'Test Program'
          fill_in 'Program Description', with: 'This is a test program description.'
          check 'No Social Media Presence'

          click_on 'Update Information'
          assert page.has_content? 'Details were successfully updated.'

          all('button', text: 'Submit for Approval').last.click
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
      login_as(partner_user)
      visit partner_user_root_path
      click_on 'My Profile'
    end

    subject { all('button', text: 'Submit for Approval').last.click }

    context "Social media information is absent" do
      before do
        partner.profile.update(website: '', facebook: '', twitter: '', instagram: '', no_social_media_presence: false)
      end

      context "partner status is invited" do
        before do
          partner.update(status: :invited)
        end

        it "should render an error message", :aggregate_failures do
          subject
          assert page.has_content? 'No social media presence must be checked if you have not provided any of Website, Twitter, Facebook, or Instagram.'
        end

        context "partner's organization one_step_partner_invite is true" do
          before do
            partner.organization.update(one_step_partner_invite: true)
          end

          it "should render an error message about social media presence only", :aggregate_failures do
            subject
            assert page.has_content? 'You have submitted your details for approval.'
          end
        end
      end

      context "partner status is awaiting_review" do
        before do
          partner.update(status: :awaiting_review)
        end

        it "should render an error message", :aggregate_failures do
          subject
          assert page.has_content? 'This partner has already requested approval.'
        end
      end
    end

    context "Mandatory fields are empty" do
      before do
        partner.update(name: '')
        partner.profile.update(
          agency_type: '',
          address1: '',
          city: '',
          state: '',
          zip_code: '',
          program_name: '',
          program_description: ''
        )
      end

      context "partner status is invited" do
        before do
          partner.update(status: :invited)
        end

        it "should render error messages for each missing field", :aggregate_failures do
          subject
          assert page.has_content? "Name can't be blank"
          assert page.has_content? "Agency type can't be blank"
          assert page.has_content? "Address1 can't be blank"
          assert page.has_content? "City can't be blank"
          assert page.has_content? "State can't be blank"
          assert page.has_content? "Zip code can't be blank"
          assert page.has_content? "Program name can't be blank"
          assert page.has_content? "Program description can't be blank"
        end
      end
    end
  end
end
