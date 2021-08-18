RSpec.describe "Partner Group management", type: :system, js: true do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  let!(:item_category_1) { create(:item_category, organization: @organization) }
  let!(:item_category_2) { create(:item_category, organization: @organization) }
  let!(:items_in_category_1) { create_list(:item, 3, item_category_id: item_category_1.id) }
  let!(:items_in_category_2) { create_list(:item, 3, item_category_id: item_category_2.id) }


  describe 'creating a new partner group' do
    it 'should allow creating a new partner group with item categories' do
      visit url_prefix + "/partners"

      click_on 'Groups'
      click_on 'New Partner Group'
      fill_in 'Name *', with: 'Test Group'

      # Click on the second item category
      find("input#partner_group_item_category_ids_#{item_category_2.id}").click

      find_button('Add Partner Group').click

      assert page.has_content? 'Group Name'
      assert page.has_content? 'Test Group'
      assert page.has_content? item_category_2.name
    end
  end

  describe 'editing a existing partner group' do
    let!(:existing_partner_group) { create(:partner_group) }
    before do
      existing_partner_group.item_categories << item_category_1
    end

    it 'should allow updating the partner name' do
      visit url_prefix + "/partners"

      click_on 'Groups'
      assert page.has_content? existing_partner_group.name
      assert page.has_content? item_category_1.name

      click_on 'Edit'
      fill_in 'Name *', with: 'New Group Name'

      # Unset the existing category
      find("input#partner_group_item_category_ids_#{item_category_1.id}").click
      # Set a new one on the category
      find("input#partner_group_item_category_ids_#{item_category_2.id}").click

      find_button('Update Partner Group').click

      assert page.has_content? 'New Group Name'
      refute page.has_content? item_category_1.name
      assert page.has_content? item_category_2.name
    end
  end
end
