RSpec.describe "Partner Dashboard", type: :system, js: true, skip_seed: true do
  describe 'Requests In Progress' do
    let(:partner_user) { partner.primary_partner_user }
    let!(:partner) { FactoryBot.create(:partner) }

    before do
      login_as(partner_user, scope: :partner_user)
    end
    context 'partners can see requests in progress' do
      # it 'has visibile requests when the status is pending' do
      let(:item1) { create(:item, name: "Good item") }
      let(:item2) { create(:item, name: "Crap item") }

      it 'displays requests that are pending' do
        FactoryBot.create(:request, :pending, partner: partner,
                                              request_items: [{ "item_id": item1.id, "quantity": '16' }])
        FactoryBot.create(:request, :pending, partner: partner,
                                              request_items: [{ "item_id": item2.id, "quantity": '16' }])
        visit partners_dashboard_path
        expect(page).to have_content(item1.name)
        expect(page).to have_content(item2.name)
      end

      it 'does not display requests in other states' do
        FactoryBot.create(:request, :fulfilled, partner: partner,
                                                request_items: [{ "item_id": item1.id, "quantity": '16' }])
        FactoryBot.create(:request, :started, partner: partner,
                                              request_items: [{ "item_id": item2.id, "quantity": '16' }])
        visit partners_dashboard_path
        expect(page).to_not have_content(item1.name)
        expect(page).to_not have_content(item2.name)
      end
    end
  end

  describe 'Distributions' do
    let(:partner_user) { partner.primary_partner_user }
    let(:date) { 1.week.from_now }
    let(:past_date) { 1.week.ago }
    let!(:partner) { FactoryBot.create(:partner) }

    before do
      login_as(partner_user, scope: :partner_user)
    end

    it 'displays upcoming distributions' do
      FactoryBot.create(:distribution, :with_items, partner: partner, organization: partner.organization, issued_at: date)
      visit partners_dashboard_path
      expect(page).to have_content("100")
      expect(page).to have_content(date.strftime("%m/%d/%Y"))
    end

    it 'displays prior distributions' do
      FactoryBot.create(:distribution, :with_items, partner: partner, organization: partner.organization,
                                                    issued_at: past_date, item_quantity: 200)
      visit partners_dashboard_path
      expect(page).to have_content("200")
      expect(page).to have_content(past_date.strftime("%m/%d/%Y"))
    end
  end
end

