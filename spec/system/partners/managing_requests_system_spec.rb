RSpec.describe "Managing requests", type: :system, js: true do
  describe 'creating a individuals/family request' do
    let(:partner_user) { partner.primary_partner_user }
    let!(:partner) { FactoryBot.create(:partner) }

    context 'GIVEN a partner user is permitted to make a request' do
      before do
        login_as(partner_user, scope: :partner_user)
        visit new_partners_individuals_request_path
      end

      context 'WHEN they create a request inproperly' do
        before do
          click_button 'Submit Essentials Request'
        end

        it 'should show an error message with the instructions ' do
          expect(page).to have_content('Opps! Something went wrong with your Request')
          expect(page).to have_content('Ensure each line item has a item selected AND a quantity greater than 0.')
          expect(page).to have_content('Still need help? Submit a support ticket here and we will do our best to follow up with you via email.')
        end
      end

      context 'WHEN they create a request properly' do
        let(:items_to_select) { Organization.find(partner_user.partner.diaper_bank_id).valid_items.sample(3) }
        let(:item_details) do
          items_to_select.map do |item|
            default_quantity = Item.find(item[:id]).default_quantity

            {
              name: item[:name],
              quantity_per_person: default_quantity,
              person_count: Faker::Number.within(range: 5..25)
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
            last_row.find_all('.form-control').last.fill_in(with: item[:person_count])
          end
        end

        context 'THEN a request records will be created and the partner will be notified via flash message on the dashboard' do
          before do
            expect { click_button 'Submit Essentials Request' }.to change { Partners::Request.count + Request.count }.by(2)

            expect(current_path).to eq(partners_request_path(Request.last.id))
            expect(page).to have_content('Request has been successfully created!')
          end

          it 'AND the partner_user can view the details of the created individuals request in a seperate page' do
            visit partners_request_path(id: Partners::Request.last.id)

            # Should have the proper quantity per each item.
            item_details.each do |item|
              expect(page).to have_content("#{item[:quantity].to_i * item[:quantity_per_person]} of #{item[:name]}")
            end
          end
        end
      end
    end
  end

  describe 'creating a request' do
    let(:partner_user) { partner.primary_partner_user }
    let!(:partner) { FactoryBot.create(:partner) }

    context 'GIVEN a partner user is permitted to make a request' do
      before do
        login_as(partner_user, scope: :partner_user)
        visit new_partners_request_path
      end

      context 'WHEN they create a request inproperly by not inputting anything' do
        before do
          click_button 'Submit Essentials Request'
        end

        it 'should show an error message with the instructions ' do
          expect(page).to have_content('Opps! Something went wrong with your Request')
          expect(page).to have_content('Ensure each line item has a item selected AND a quantity greater than 0.')
          expect(page).to have_content('Still need help? Submit a support ticket here and we will do our best to follow up with you via email.')
        end
      end

      context 'WHEN they create a request with only a comment' do
        before do
          fill_in 'Comments', with: Faker::Lorem.paragraph
        end

        it 'should be created without any issue' do
          expect { click_button 'Submit Essentials Request' }.to change { Partners::Request.count + Request.count }.by(2)

          expect(current_path).to eq(partners_request_path(Request.last.id))
          expect(page).to have_content('Request has been successfully created!')
          expect(page).to have_content("#{partner.organization.name} should have received the request.")
        end
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

          # Trigger another row but keep it empty. It should still be valid!
          click_link 'Add Another Item'
        end

        context 'THEN a request records will be created and the partner will be notified via flash message on the dashboard' do
          before do
            expect { click_button 'Submit Essentials Request' }.to change { Partners::Request.count + Request.count }.by(2)

            expect(current_path).to eq(partners_request_path(Request.last.id))
            expect(page).to have_content('Request has been successfully created!')
            expect(page).to have_content("#{partner.organization.name} should have received the request.")
          end

          it 'AND the partner_user can view the details of the created request in a seperate page' do
            visit partners_request_path(id: Partners::Request.last.id)

            item_details.each do |item|
              expect(page).to have_content("#{item[:quantity]} of #{item[:name]}")
            end
          end
        end
      end
    end
  end
end


