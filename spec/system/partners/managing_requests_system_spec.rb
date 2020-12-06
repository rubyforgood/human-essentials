RSpec.describe "Managing requests", type: :system, js: true do
  describe 'creating a request' do
    let!(:partner_user) { FactoryBot.create(:partners_user) }

    context 'GIVEN a partner user is permitted to make a request' do
      before do
        login_as(partner_user, scope: :partner_user)
        visit new_partners_request_path
      end

      context 'WHEN they create a request properly' do
        let(:items_to_select) { Organization.find(partner_user.partner.diaper_bank_id).valid_items.sample(3) }

        before do
          fill_in 'Comments', with: Faker::Lorem.paragraph

          # Select items
          items_to_select.each_with_index do |item, idx|
            if idx != 0
              click_link 'Add Another Item'
            end

            last_row = find_all('tr').last
            last_row.find('option', text: item[:name]).select_option
            last_row.find_all('.form-control').last.fill_in(with: Faker::Number.within(range: 5..25))
          end
        end

        it 'THEN a request records will be created and the partner will be notified via flash message on the dashboard' do
          # Ensure all records are created
          expect { click_button 'Submit Essentials Request' }.to change { Partners::Request.count + Request.count }.by(2)

          expect(current_path).to eq(partners_dashboard_path)
          expect(page).to have_content('Request was successfully created.')
        end
      end
    end
  end
end


