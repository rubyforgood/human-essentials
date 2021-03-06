RSpec.describe "Managing requests", type: :system, js: true do
  describe 'creating a request' do
    let(:partner_user) { partner.primary_partner_user }
    let!(:partner) { FactoryBot.create(:partner) }

    context 'GIVEN a partner user is permitted to make a request' do
      before do
        login_as(partner_user, scope: :partner_user)
        visit new_partners_request_path
      end

      context 'WHEN they create a request properly' do
        let(:items_to_select) { Organization.find(partner_user.partner.diaper_bank_id).valid_items.sample(3) }
        let(:item_details) do
          items_to_select.map do |item|
            {
              name: item[:name],
              quantity: Faker::Number.within(range: 5..25)
            }
          end
        end

        before do
          fill_in 'Comments', with: Faker::Lorem.paragraph

          # Select items
          item_details.each_with_index do |item, idx|
            if idx != 0
              click_link 'Add Another Item'
            end

            last_row = find_all('tr').last
            last_row.find('option', text: item[:name], exact_text: true).select_option
            last_row.find_all('.form-control').last.fill_in(with: item[:quantity])
          end
        end

        context 'THEN a request records will be created and the partner will be notified via flash message on the dashboard' do
          before do
            expect { click_button 'Submit Essentials Request' }.to change { Partners::Request.count + Request.count }.by(2)

            expect(current_path).to eq(partners_dashboard_path)
            expect(page).to have_content('Request was successfully created.')
          end

          it 'AND the partner_user can view the details of the created request in a seperate page' do
            partner_request_id = Partners::Request.last.id

            visit partners_request_path(id: Partners::Request.last.id)

            expect(page).to have_content("#{partner_user.partner.name} Request ID: #{partner_request_id}")
            item_details.each do |item|
              expect(page).to have_content("#{item[:quantity]} of #{item[:name]}")
            end
          end
        end
      end
    end
  end
end


