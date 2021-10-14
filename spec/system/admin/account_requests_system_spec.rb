RSpec.describe "Account Requests Admin", type: :system do
  context "while signed in as a super admin" do
    before do
      sign_in(@super_admin)
    end

    context "user visits the index page" do
      let!(:request1) { create(:account_request, confirmed_at: Time.zone.today) }
      let!(:request2) { create(:account_request, confirmed_at: Time.zone.today - 1.day) }
      let!(:request3) { create(:account_request, confirmed_at: Time.zone.today - 2.days) }
      let!(:request4) { create(:account_request, created_at: Time.zone.today) }
      let!(:request5) { create(:account_request, created_at: Time.zone.today - 1.day) }
      let!(:request6) { create(:account_request, created_at: Time.zone.today - 2.days) }

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
            expect(page).to have_content(request.status)
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
            expect(page).to have_content(request.status)
            expect(page).to have_content(request.name)
            expect(page).to have_content(request.email)
          end
          expect(page).to_not have_content(request4.name)
        end
      end
    end
  end
end
