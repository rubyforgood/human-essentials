RSpec.describe "Managing requests", type: :system, js: true do
  describe 'creating a # individuals request' do
    let(:partner_user) { partner.primary_user }
    let!(:partner) { FactoryBot.create(:partner, status: :approved) }

    context 'GIVEN a partner user is permitted to make a request' do
      before do
        login_as(partner_user)
        visit new_partners_individuals_request_path
      end

      context 'WHEN a request is built using add and remove buttons' do
        let(:items_to_select) { partner_user.partner.organization.valid_items.sample(3) }
        let(:item_details) do
          items_to_select.map do |item|
            default_quantity = Item.find(item[:id]).default_quantity

            {
              name: item[:name],
              id: item[:id],
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

          # delete an item
          find_all('td').last.click
        end

        context 'THEN a request records will be created' do
          it "creates the correct request" do
            click_button 'Submit Essentials Request'
            expect(page).to have_selector('#partnerIndividualRequestConfirmationModal')
            within "#partnerIndividualRequestConfirmationModal" do
              click_button "Yes, it's correct"
            end

            created_request = Request.last
            expected_items = item_details.map { |item| {"item_id" => item[:id], "quantity" => item[:quantity_per_person] * item[:person_count]} }
            deleted_item = expected_items.pop

            expect(created_request.request_items).to match_array(expected_items)
            expect(created_request.request_items).to_not include(deleted_item)
          end
        end
      end
    end
  end

  describe 'creating a new quantity request' do
    let(:organization) { FactoryBot.create(:organization, :with_items) }
    let(:partner_user) { partner.primary_user }
    let!(:partner) { FactoryBot.create(:partner, organization: organization, quota: 1) }

    context 'GIVEN a partner user is permitted to make a request' do
      before do
        login_as(partner_user)
        visit new_partners_request_path
      end

      context 'WHEN a request is built using add and remove buttons' do
        let(:items_to_select) { partner_user.partner.organization.valid_items.sample(3) }
        let(:item_details) do
          items_to_select.map do |item|
            {
              id: item[:id],
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

          # Remove the last item
          last_row = find_all('tr').last
          last_row.find('a', text: 'Remove').click

          # Trigger another row but keep it empty. It should still be valid!
          click_link 'Add Another Item'
        end

        context 'THEN a request records will be created ' do
          it "displays confirmation modal with quota warning and creates the correct request" do
            click_button 'Submit Essentials Request'
            expect(page).to have_selector('.alert-warning')
            expect(page).to have_text('You are ordering')
            expect(page).to have_text('total items, are you sure?')
            expect(page).to have_selector('#partnerRequestConfirmationModal')
            within "#partnerRequestConfirmationModal" do
              click_button "Yes, it's correct"
            end
            created_request = Request.last
            expected_items = item_details.map { |item| {"item_id" => item[:id], "quantity" => item[:quantity]} }
            deleted_item = expected_items.pop

            expect(created_request.request_items).to match_array(expected_items)
            expect(created_request.request_items).to_not include(deleted_item)
          end
        end
      end
    end
  end
end
