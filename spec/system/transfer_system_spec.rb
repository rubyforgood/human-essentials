RSpec.describe "Transfer management", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }

  before do
    sign_in(user)
  end
  let(:item) { create(:item) }

  def create_transfer(amount, from_name, to_name)
    visit transfers_path
    click_link "New Transfer"
    within "form#new_transfer" do
      select from_name, from: "From storage location"
      select to_name, from: "To storage location"
      fill_in "Comment", with: "something"
      select item.name, from: "transfer_line_items_attributes_0_item_id"
      fill_in "transfer_line_items_attributes_0_quantity", with: amount
    end
    click_on "Save"
  end

  it "can transfer an inventory from a storage location to another as a user" do
    from_storage_location = create(:storage_location, :with_items, item: item, name: "From me", organization: organization)
    to_storage_location = create(:storage_location, :with_items, name: "To me", organization: organization)
    create_transfer("10", from_storage_location.name, to_storage_location.name)
    expect(page).to have_content("10 items have been transferred")
  end

  it "can delete a transfer to undo the inventory count changes" do
    from_storage_location = create(:storage_location, :with_items, item: item, name: "From me", organization: organization)
    to_storage_location = create(:storage_location, :with_items, name: "To me", organization: organization)

    inventory = View::Inventory.new(organization.id)
    original_from_storage_item_count = inventory.quantity_for(storage_location: from_storage_location.id, item_id: item.id)
    original_from_ii_storage_item_count = from_storage_location.inventory_items.find_by(item_id: item.id).quantity
    expect(original_from_storage_item_count).to eq(original_from_ii_storage_item_count)
    original_to_storage_item_count = 0
    transfer_amount = 10

    create_transfer(transfer_amount.to_s, from_storage_location.name, to_storage_location.name)

    inventory.reload

    # Ensure the that the transfer has changed the inventory quantities
    expect(from_storage_location.reload.inventory_items.find_by(item_id: item.id).quantity).not_to eq(original_from_storage_item_count)
    expect(to_storage_location.reload.inventory_items.find_by(item_id: item.id).quantity).to eq(transfer_amount)
    expect(inventory.quantity_for(storage_location: from_storage_location.id, item_id: item.id)).not_to eq(original_from_storage_item_count)
    expect(inventory.quantity_for(storage_location: to_storage_location.id, item_id: item.id)).to eq(transfer_amount)

    accept_confirm do
      click_link 'Delete'
    end

    expect(page).to have_content(/Succesfully deleted Transfer/)

    inventory.reload

    # Assert that the original inventory counts have been restored.
    expect(from_storage_location.reload.inventory_items.find_by(item_id: item.id).quantity).to eq(original_from_storage_item_count)
    expect(to_storage_location.reload.inventory_items.find_by(item_id: item.id).quantity).to eq(original_to_storage_item_count)
    expect(inventory.quantity_for(storage_location: from_storage_location.id, item_id: item.id)).to eq(original_from_storage_item_count)
    expect(inventory.quantity_for(storage_location: to_storage_location.id, item_id: item.id)).to eq(original_to_storage_item_count)
  end

  it 'shows a error when deleting a transfer that causes an insufficient inventory counts' do
    from_storage_location = create(:storage_location, :with_items, item: item, name: "From me", organization: organization)
    to_storage_location = create(:storage_location, :with_items, name: "To me", organization: organization)

    inventory = View::Inventory.new(organization.id)
    original_from_storage_item_count = inventory.quantity_for(storage_location: from_storage_location.id, item_id: item.id)
    original_from_ii_storage_item_count = from_storage_location.inventory_items.find_by(item_id: item.id).quantity
    expect(original_from_storage_item_count).to eq(original_from_ii_storage_item_count)
    transfer_amount = 10

    create_transfer(transfer_amount.to_s, from_storage_location.name, to_storage_location.name)
    inventory.reload

    expect(from_storage_location.reload.inventory_items.find_by(item_id: item.id).quantity).to eq(original_from_storage_item_count - transfer_amount)
    expect(to_storage_location.reload.inventory_items.find_by(item_id: item.id).quantity).to eq(transfer_amount)
    expect(inventory.quantity_for(storage_location: from_storage_location.id, item_id: item.id)).to eq(original_from_storage_item_count - transfer_amount)
    expect(inventory.quantity_for(storage_location: to_storage_location.id, item_id: item.id)).to eq(transfer_amount)

    allow_any_instance_of(StorageLocation).to receive(:decrease_inventory).and_raise(
      Errors::InsufficientAllotment.new('error-msg', [])
    )

    accept_confirm do
      click_link 'Delete'
    end

    expect(page).to have_content(/error-msg/)
    inventory.reload

    # Assert that the inventory did not change in response
    # to the raised error.
    expect(from_storage_location.reload.inventory_items.find_by(item_id: item.id).quantity).to eq(original_from_storage_item_count - transfer_amount)
    expect(to_storage_location.reload.inventory_items.find_by(item_id: item.id).quantity).to eq(transfer_amount)
    expect(inventory.quantity_for(storage_location: from_storage_location.id, item_id: item.id)).to eq(original_from_storage_item_count - transfer_amount)
    expect(inventory.quantity_for(storage_location: to_storage_location.id, item_id: item.id)).to eq(transfer_amount)
  end

  it 'should not include inactive storage locations in dropdowns when creating a new transfer' do
    create(:storage_location, name: "Inactive R Us", discarded_at: Time.zone.now)
    visit new_transfer_path
    expect(page).to have_no_text 'Inactive R Us'
  end

  # 4438 - Bug Fix
  it "add item button should be activated when from storage location is selected after rendering again on failure" do
    from_storage_location = create(:storage_location, :with_items, item: item, name: "From me", organization: organization)
    create_transfer('', '', '')
    select from_storage_location.name, from: "From storage location"
    expect(page).not_to have_css("#__add_line_item.disabled")
  end

  context "when there's insufficient inventory at the origin to cover the move" do
    let!(:from_storage_location) { create(:storage_location, :with_items, item: item, item_quantity: 10, name: "From me", organization: organization) }
    let!(:to_storage_location) { create(:storage_location, :with_items, name: "To me", organization: organization) }

    scenario "User can transfer an inventory from a storage location to another" do
      create_transfer("100", from_storage_location.name, to_storage_location.name)
      expect(page).to have_content("insufficient inventory")
    end
  end

  context "when viewing the index page" do
    subject { transfers_path }
    it "can filter the #index by storage location both from and to as a user" do
      from_storage_location = create(:storage_location, name: "here", organization: organization)
      to_storage_location = create(:storage_location, name: "there", organization: organization)
      create(:transfer, organization: organization, from: from_storage_location, to: to_storage_location)
      create(:transfer, organization: organization, from: to_storage_location, to: from_storage_location)

      visit subject
      select to_storage_location.name, from: "filters[to_location]"
      click_button "Filter"

      expect(page).to have_css("table tr", count: 2)

      visit subject
      select from_storage_location.name, from: "filters[from_location]"
      click_button "Filter"

      expect(page).to have_css("table tr", count: 2)
    end

    it_behaves_like "Date Range Picker", Transfer
  end
end
