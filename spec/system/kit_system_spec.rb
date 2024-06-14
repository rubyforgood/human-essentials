RSpec.describe "Kit management", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end

  let!(:storage_location) { create(:storage_location, organization: organization) }
  let!(:existing_kit) do
    kit_params = {
      organization_id: organization.id,
      name: Faker::Appliance.equipment,
      line_items_attributes: {
        "0": { item_id: existing_kit_item_1.id, quantity: existing_kit_item_1_quantity },
        "1": { item_id: existing_kit_item_2.id, quantity: existing_kit_item_2_quantity }
      }
    }
    kit_creation_service = KitCreateService.new(organization_id: organization.id, kit_params: kit_params).tap(&:call)
    kit_creation_service.kit
  end

  let!(:existing_kit_item_1) { create(:item) }
  let!(:existing_kit_item_1_quantity) { 5 }
  let!(:existing_kit_item_2) { create(:item) }
  let!(:existing_kit_item_2_quantity) { 3 }
  before(:each) do
    TestInventory.create_inventory(organization, {
      storage_location.id => {
        existing_kit_item_1.id => 50,
        existing_kit_item_2.id => 50
      }
    })
  end

  it "can create a new kit as a user with the proper quantity" do
    visit new_kit_path
    kit_traits = attributes_for(:kit)

    fill_in "Name", with: kit_traits[:name]
    find(:css, '#kit_value_in_dollars').set('10.10')

    item = Item.last
    quantity_per_kit = 5
    select item.name, from: "kit_line_items_attributes_0_item_id"
    find(:css, '#kit_line_items_attributes_0_quantity').set(quantity_per_kit)

    click_button "Save"

    expect(page.find(".alert")).to have_content "Kit created successfully"
    expect(page).to have_content(kit_traits[:name])
    expect(page).to have_content("#{quantity_per_kit} #{item.name}")
  end

  it 'can allocate and deallocate quantity per storage location from kit index' do
    visit kits_path

    click_on 'Modify Allocation'

    inventory = View::Inventory.new(organization.id)
    original_kit_count = inventory.quantity_for(item_id: existing_kit.item.id, storage_location: storage_location.id)
    original_item_1_count = inventory.quantity_for(item_id: existing_kit_item_1.id, storage_location: storage_location.id)
    original_item_2_count = inventory.quantity_for(item_id: existing_kit_item_2.id, storage_location: storage_location.id)

    original_ii_kit_count = existing_kit.inventory_items.find_by(storage_location_id: storage_location.id)&.quantity || 0
    original_ii_item_1_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity
    original_ii_item_2_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity

    expect(original_kit_count).to eq(0)
    expect(original_kit_count).to eq(original_ii_kit_count)
    expect(original_item_1_count).to eq(50)
    expect(original_item_1_count).to eq(original_ii_item_1_count)
    expect(original_item_2_count).to eq(50)
    expect(original_item_2_count).to eq(original_ii_item_2_count)

    select storage_location.name, from: 'kit_adjustment_storage_location_id'

    change_quantity_by = 2
    find(:css, '#kit_adjustment_change_by').set(change_quantity_by)

    click_on 'Save'

    inventory.reload

    # Check that the kit quantity increased by the expected amount
    expect(existing_kit.reload.inventory_items.find_by(storage_location_id: storage_location.id).quantity).to eq(2)
    expect(inventory.quantity_for(item_id: existing_kit.item.id, storage_location: storage_location.id)).to eq(2)

    # Ensure each of the contained items decrease the correct amount
    expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity).to eq(40)
    expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity).to eq(44)
    expect(inventory.quantity_for(item_id: existing_kit_item_1.id, storage_location: storage_location.id)).to eq(40)
    expect(inventory.quantity_for(item_id: existing_kit_item_2.id, storage_location: storage_location.id)).to eq(44)

    # Perform reverse operation. That is, decrease the quantity count of kits
    # should increase the contained items quantity count
    select storage_location.name, from: 'kit_adjustment_storage_location_id'
    find(:css, '#kit_adjustment_change_by').set(-1 * change_quantity_by)

    click_on 'Save'
    inventory.reload

    # Ensure each of the contained items decrease the correct amount
    expect(existing_kit.reload.inventory_items.find_by(storage_location_id: storage_location.id).quantity).to eq(0)
    expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity).to eq(50)
    expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity).to eq(50)

    expect(inventory.quantity_for(item_id: existing_kit.item.id, storage_location: storage_location.id)).to eq(0)
    expect(inventory.quantity_for(item_id: existing_kit_item_1.id, storage_location: storage_location.id)).to eq(50)
    expect(inventory.quantity_for(item_id: existing_kit_item_2.id, storage_location: storage_location.id)).to eq(50)
  end

  it 'should not display inactive storage locations under allocations' do
    inactive_location = create(:storage_location, organization_id: organization.id, name: "Inactive R Us", discarded_at: Time.zone.now)
    setup_storage_location(inactive_location)
    kit_params = {
      organization_id: organization.id,
      name: "Fake Kit"
    }
    KitCreateService.new(organization_id: organization.id, kit_params: kit_params).tap(&:call).kit
    visit kits_path
    expect(page).to have_no_text("Inactive R Us")
  end

  context 'when there is not enough quantity of the items contained in the kit on-hand' do
    before do
      # Force there to be no loose items available
      TestInventory.clear_inventory(storage_location)
    end

    it 'will not change quantity amounts when allocating' do
      visit kits_path

      click_on 'Modify Allocation'

      inventory = View::Inventory.new(organization.id)
      original_kit_count = inventory.quantity_for(item_id: existing_kit.item.id, storage_location: storage_location.id)
      original_item_1_count = inventory.quantity_for(item_id: existing_kit_item_1.id, storage_location: storage_location.id)
      original_item_2_count = inventory.quantity_for(item_id: existing_kit_item_2.id, storage_location: storage_location.id)

      original_ii_kit_count = existing_kit.inventory_items.find_by(storage_location_id: storage_location.id)&.quantity || 0
      original_ii_item_1_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id)&.quantity || 0
      original_ii_item_2_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id)&.quantity || 0

      expect(original_kit_count).to eq(0)
      expect(original_kit_count).to eq(original_ii_kit_count)
      expect(original_item_1_count).to eq(0)
      expect(original_item_1_count).to eq(original_ii_item_1_count)
      expect(original_item_2_count).to eq(0)
      expect(original_item_2_count).to eq(original_ii_item_2_count)

      select storage_location.name, from: 'kit_adjustment_storage_location_id'

      change_quantity_by = 1
      find(:css, '#kit_adjustment_change_by').set(change_quantity_by)

      click_on 'Save'
      inventory.reload

      expect(existing_kit.reload.inventory_items.find_by(storage_location_id: storage_location.id)&.quantity || 0).to eq(0)
      expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id)&.quantity || 0).to eq(0)
      expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id)&.quantity || 0).to eq(0)

      expect(inventory.quantity_for(item_id: existing_kit.item.id, storage_location: storage_location.id)).to eq(0)
      expect(inventory.quantity_for(item_id: existing_kit_item_1.id, storage_location: storage_location.id)).to eq(0)
      expect(inventory.quantity_for(item_id: existing_kit_item_2.id, storage_location: storage_location.id)).to eq(0)
    end
  end

  context 'when there is no kit quantity' do
    before do
      # Force there to be no kit quantity available
      TestInventory.create_inventory(organization, {
        storage_location.id => {
          existing_kit.item.id => 0,
          existing_kit_item_1.id => 50,
          existing_kit_item_2.id => 50
        }
      })
    end

    it 'will not change quantity amounts when deallocating' do
      visit kits_path

      click_on 'Modify Allocation'

      inventory = View::Inventory.new(organization.id)
      original_kit_count = inventory.quantity_for(item_id: existing_kit.item.id, storage_location: storage_location.id)
      original_item_1_count = inventory.quantity_for(item_id: existing_kit_item_1.id, storage_location: storage_location.id)
      original_item_2_count = inventory.quantity_for(item_id: existing_kit_item_2.id, storage_location: storage_location.id)

      original_ii_kit_count = existing_kit.inventory_items.find_by(storage_location_id: storage_location.id)&.quantity || 0
      original_ii_item_1_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity
      original_ii_item_2_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity

      expect(original_kit_count).to eq(0)
      expect(original_kit_count).to eq(original_ii_kit_count)
      expect(original_item_1_count).to eq(50)
      expect(original_item_1_count).to eq(original_ii_item_1_count)
      expect(original_item_2_count).to eq(50)
      expect(original_item_2_count).to eq(original_ii_item_2_count)

      select storage_location.name, from: 'kit_adjustment_storage_location_id'

      change_quantity_by = -1
      find(:css, '#kit_adjustment_change_by').set(change_quantity_by)

      click_on 'Save'
      inventory.reload

      expect(existing_kit.reload.inventory_items.find_by(storage_location_id: storage_location.id)&.quantity || 0).to eq(0)
      expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity).to eq(50)
      expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity).to eq(50)

      expect(inventory.quantity_for(item_id: existing_kit.item.id, storage_location: storage_location.id)).to eq(0)
      expect(inventory.quantity_for(item_id: existing_kit_item_1.id, storage_location: storage_location.id)).to eq(50)
      expect(inventory.quantity_for(item_id: existing_kit_item_2.id, storage_location: storage_location.id)).to eq(50)
    end
  end

  describe "when missing required fields" do
    it "displays error indicating missing field and preserves filled out fields" do
      visit new_kit_path
      kit_traits = attributes_for(:kit)

      find(:css, '#kit_value_in_dollars').set('10.10')

      item = Item.last
      quantity_per_kit = 5
      select item.name, from: "kit_line_items_attributes_0_item_id"
      find(:css, '#kit_line_items_attributes_0_quantity').set(quantity_per_kit)

      click_button "Save"

      expect(page.find(".alert")).to have_content "Name can't be blank"
      expect(page).to have_content(kit_traits[:quantity])
      expect(page).to have_content(item.name)
    end
  end
end
