RSpec.describe "Kit management", type: :system do
  before do
    sign_in(@user)
  end
  let!(:storage_location) do
    location = create(:storage_location, organization: @organization)
    setup_storage_location(location)
    location
  end
  let!(:existing_kit) do
    kit_params = {
      organization_id: @organization.id,
      name: Faker::Appliance.equipment,
      line_items_attributes: {
        "0": { item_id: existing_kit_item_1.id, quantity: existing_kit_item_1_quantity },
        "1": { item_id: existing_kit_item_2.id, quantity: existing_kit_item_2_quantity }
      }
    }
    kit_creation_service = KitCreateService.new(organization_id: @organization.id, kit_params: kit_params).tap(&:call)
    kit_creation_service.kit
  end
  let!(:existing_kit_item_1) { storage_location.items.first }
  let!(:existing_kit_item_1_quantity) { 5 }
  let!(:existing_kit_item_2) { storage_location.items.last }
  let!(:existing_kit_item_2_quantity) { 3 }

  let!(:url_prefix) { "/#{@organization.to_param}" }

  it "can create a new kit as a user with the proper quantity" do
    visit url_prefix + "/kits/new"
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
    visit url_prefix + "/kits/"

    click_on 'Modify Allocation'

    original_kit_count = existing_kit.inventory_items.find_by(storage_location_id: storage_location.id).quantity
    original_item_1_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity
    original_item_2_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity

    select storage_location.name, from: 'kit_adjustment_storage_location_id'

    change_quantity_by = 2
    find(:css, '#kit_adjustment_change_by').set(change_quantity_by)

    click_on 'Save'

    # Check that the kit quantity increased by the expected amount
    expect(existing_kit.reload.inventory_items.find_by(storage_location_id: storage_location.id).quantity).to eq(original_kit_count + change_quantity_by)

    # Ensure each of the contained items decrease the correct amount
    expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity).to eq(original_item_1_count - (change_quantity_by * existing_kit_item_1_quantity))
    expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity).to eq(original_item_2_count - (change_quantity_by * existing_kit_item_2_quantity))

    # Perform reverse operation. That is, decrease the quantity count of kits
    # should increase the contained items quantity count
    select storage_location.name, from: 'kit_adjustment_storage_location_id'
    find(:css, '#kit_adjustment_change_by').set(-1 * change_quantity_by)

    click_on 'Save'

    # Ensure each of the contained items decrease the correct amount
    expect(existing_kit.reload.inventory_items.find_by(storage_location_id: storage_location.id).quantity).to eq(original_kit_count)
    expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity).to eq(original_item_1_count)
    expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity).to eq(original_item_2_count)
  end

  it 'should not display inactive storage locations under allocations' do
    inactive_location = create(:storage_location, organization_id: @organization.id, name: "Inactive R Us", discarded_at: Time.zone.now)
    setup_storage_location(inactive_location)
    kit_params = {
      organization_id: @organization.id,
      name: "Fake Kit"
    }
    KitCreateService.new(organization_id: @organization.id, kit_params: kit_params).tap(&:call).kit
    visit url_prefix + "/kits/"
    expect(page).to have_no_text("Inactive R Us")
  end

  context 'when there is not enough quantity of the items contained in the kit on-hand' do
    before do
      # Force there to be no loose items available
      InventoryItem.all.each { |ii| ii.update(quantity: 0) }
    end

    it 'will not change quantity amounts when allocating' do
      visit url_prefix + "/kits/"

      click_on 'Modify Allocation'

      original_kit_count = existing_kit.inventory_items.find_by(storage_location_id: storage_location.id).quantity
      original_item_1_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity
      original_item_2_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity

      select storage_location.name, from: 'kit_adjustment_storage_location_id'

      change_quantity_by = 1
      find(:css, '#kit_adjustment_change_by').set(change_quantity_by)

      click_on 'Save'

      expect(existing_kit.reload.inventory_items.find_by(storage_location_id: storage_location.id).quantity).to eq(original_kit_count)
      expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity).to eq(original_item_1_count)
      expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity).to eq(original_item_2_count)
    end
  end

  context 'when there is no kit quantity' do
    before do
      # Force there to be no kit quantity available
      existing_kit.inventory_items.find_by(storage_location_id: storage_location.id).update(quantity: 0)
    end

    it 'will not change quantity amounts when deallocating' do
      visit url_prefix + "/kits/"

      click_on 'Modify Allocation'

      original_kit_count = existing_kit.inventory_items.find_by(storage_location_id: storage_location.id).quantity
      original_item_1_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity
      original_item_2_count = storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity

      select storage_location.name, from: 'kit_adjustment_storage_location_id'

      change_quantity_by = -1
      find(:css, '#kit_adjustment_change_by').set(change_quantity_by)

      click_on 'Save'

      expect(existing_kit.reload.inventory_items.find_by(storage_location_id: storage_location.id).quantity).to eq(original_kit_count)
      expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_1.id).quantity).to eq(original_item_1_count)
      expect(storage_location.inventory_items.find_by(item_id: existing_kit_item_2.id).quantity).to eq(original_item_2_count)
    end
  end
end
