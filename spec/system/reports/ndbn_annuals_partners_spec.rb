RSpec.describe "NDBN Reports", type: :system, js: true do
  describe 'Partnert Agencies and Service Area' do
    include_examples 'partner reporter service stubs'
    let!(:partner1) { create(:partner, created_at: Time.zone.today) }
    let!(:partner2) { create(:partner, created_at: Time.zone.today - 1.day) }
    let!(:partner3) { create(:partner, created_at: Time.zone.today - 7.days) }
    let!(:partner4) { create(:partner, created_at: Time.zone.today - 2.years) }

    before do
      @url_prefix = "/#{@organization.short_name}/reports/ndbn_annuals"
      user = create(:user, organization: @organization)
      partners = @organization.partners.during(Time.zone.today.beginning_of_year.beginning_of_day..Time.zone.today.end_of_year.end_of_day)
      results = prepare_results(partners)
      partners.each do |partner|
        stub_partner_call_result(partner: partner, results: results)
      end
      sign_in(user)
    end

    subject { @url_prefix + "/#{Time.zone.today.year}" }

    context 'Total Partners' do
      it 'must have two partners in count' do
        visit subject
        within '#partners' do
          expect(page).to have_content('4')
        end

        partner2.update(created_at: Time.zone.today - 2.years)
        visit subject
        within '#partners' do
          expect(page).to have_content('3')
        end
      end
    end

    context 'Partner Agencies types' do
      before do
        visit subject
      end

      it 'total of Family Resource Center' do
        within "#partners-types" do
          expect(page).to have_content('Family Resource Center (2)')
        end
      end

      it 'total of Child Abuse Resource Center' do
        within "#partners-types" do
          expect(page).to have_content('Child Abuse Resource Center (1)')
        end
      end

      it 'total of Some kind of type' do
        within "#partners-types" do
          expect(page).to have_content('Some kind of type (1)')
        end
      end
    end

    context 'Partner Service areas' do
      before do
        visit subject
      end

      it 'must have non repeated zip codes' do
        within '#service-areas' do
          expect(page).to have_content('12441, 014785, 3457100')
        end
      end
    end

    context 'when no report is found for the year' do
      before do
        Partner.all.each { |partner| partner.update(created_at: Time.zone.today - 2.years) }
        visit subject
      end

      it 'must show a meaningfull message' do
        expect(page).to have_content("No report found for #{Time.zone.today.year}")
      end
    end
  end
end
