RSpec.describe "Account Requests Admin", type: :system do
  let(:super_admin) { create(:super_admin) }

  context "while signed in as a super admin" do
    let!(:request1) { create(:account_request, confirmed_at: Time.zone.today, status: 'admin_approved') }
    let!(:request2) {
      create(:account_request, confirmed_at: Time.zone.today - 1.day,
        status: 'rejected', rejection_reason: 'Because I said so')
    }
    let!(:request3) { create(:account_request, confirmed_at: Time.zone.today - 2.days, status: 'admin_approved') }
    let!(:request4) { create(:account_request, created_at: Time.zone.today, status: 'user_confirmed') }
    let!(:request5) { create(:account_request, created_at: Time.zone.today - 1.day, status: 'started') }
    let!(:request6) { create(:account_request, created_at: Time.zone.today - 2.days, status: 'started') }

    before do
      sign_in(super_admin)
    end

    around do |ex|
      freeze_time do
        ex.run
      end
    end

    context "user visits the for_rejection page" do
      before do
        allow(AccountRequest).to receive(:get_by_identity_token).and_return(request4)
        visit for_rejection_admin_account_requests_path(token: 'my token')
      end

      it 'should reject the account', js: true do
        find(%(a[data-request-id="#{request4.id}"])).click
        fill_in 'account_request_rejection_reason', with: 'Because I said so'
        click_on 'Save'
        expect(request4.reload).to be_rejected
        within "#closed-account-requests" do
          expect(page).to have_content(request4.name)
        end
        within '#open-account-requests' do
          expect(page).not_to have_content(request4.name)
        end
      end
    end

    context "user visits the index page" do
      before do
        visit admin_account_requests_path
      end

      it 'shows unconfirmed account requests within appropriate table' do
        expect(page).to have_css("table", id: "open-account-requests")

        within "#open-account-requests" do
          [request4, request5, request6].each do |request|
            expect(page).to have_content(request.created_at.strftime("%m/%d/%Y"))
            expect(page).to have_content(request.organization_name)
            expect(page).to have_content(request.organization_website)
            expect(page).to have_content(request.request_details)
            expect(page).to have_content(request.status.titleize)
            expect(page).to have_content(request.name)
            expect(page).to have_content(request.email)
          end
          expect(page).to_not have_content(request1.name)
        end
      end

      it 'shows confirmed account requests within appropriate table' do
        expect(page).to have_css("table", id: "open-account-requests")

        within "#closed-account-requests" do
          [request1, request2, request3].each do |request|
            expect(page).to have_content(request.created_at.strftime("%m/%d/%Y"))
            expect(page).to have_content(request.organization_name)
            expect(page).to have_content(request.organization_website)
            expect(page).to have_content(request.request_details)
            expect(page).to have_content(request.status.titleize)
            expect(page).to have_content(request.name)
            expect(page).to have_content(request.email)
          end
          expect(page).to have_content('Because I said so')
          expect(page).to_not have_content(request4.name)
        end
      end
    end

    context "user rejects an account request" do
      before do
        visit admin_account_requests_path
      end

      it 'should reject the account', js: true do
        find(%(a[data-request-id="#{request4.id}"])).click
        fill_in 'account_request_rejection_reason', with: 'Because I said so'
        click_on 'Save'
        expect(request4.reload).to be_rejected
        within "#closed-account-requests" do
          expect(page).to have_content(request4.name)
        end
        within '#open-account-requests' do
          expect(page).not_to have_content(request4.name)
        end
      end
    end
  end
end
