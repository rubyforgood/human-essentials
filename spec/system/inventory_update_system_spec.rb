RSpec.feature "Distributions", type: :system do
  before do
    sign_in(@user)
    @url_prefix = "/#{@organization.to_param}"

    @partner = create(:partner, organization: @organization)

    @storage_location = create(:storage_location, organization: @organization)
    setup_storage_location(@storage_location)
  end

  describe "ensuring multiple clicks do not cause 'inventory drift'" do
    let(:item_1) { create(:item, name: "Test Item One", organization: @organization) }
    let(:item_2) { create(:item, name: "Test Item Two", organization: @organization) }

    let!(:donation_with_item_1) { create(:donation, :with_items, organization: @organization, storage_location: @storage_location, item_quantity: 100, item: item_1) }
    let!(:donation_with_item_2) { create(:donation, :with_items, organization: @organization, storage_location: @storage_location, item_quantity: 1000, item: item_2) }

    it "properly adjusts inventory if we click the save multiple times on a distribution correction" do
      # What we did to test this manually
      # check the inventory level on 2 items  (I don't think we need to actually visit the inventory screen for this)
      # enter a new distribution with those items
      # (check the inventory levels again - is adjusted properly (I think we can skip that in the final version of this recreation))
      # bring up the distribution for a correction
      # change the second item
      # click the save button very quickly about 5 times
      # check the resulting 'show' screen [should show the changed values, not a multiple of them]
      # check the inventory levels .
      # The question for whether this test will work is whether we can appropriately simulate clicking the save button very quickly.
      # We might not get the bad results!  So it's really important to do the *RED* part of the cycle to confirm that it fails

      # Set up items and initial inventory level
      ii_1 = InventoryItem.where(storage_location: @storage_location, item: item_1).first
      ii_2 = InventoryItem.where(storage_location: @storage_location, item: item_2).first

      # Paranoid check that things are what we expect them to be before we start [should be able to eliminate later]
      expect(ii_1.quantity).to eq(100)
      expect(ii_2.quantity).to eq(1000)

      # Enter a distribution with 5 Test Item One and 4 Test Item Two

      visit @url_prefix + "/distributions/new"

      select @partner.name, from: "Partner"
      select @storage_location.name, from: "From storage location"
      choose "Pick up"

      fill_in "Comment", with: "Take my wipes... please"
      fill_in "Distribution date", with: "01/01/2001 10:15:00 AM"

      select item_1.name, from: "distribution_line_items_attributes_0_item_id"
      fill_in "distribution_line_items_attributes_0_quantity", with: 5

      click_on "Add another item"

      second_drop_down_id = page.find_all(".distribution_line_items_item_id")[1].first("select")[:id]
      select item_2.name, from: second_drop_down_id
      find_all(".numeric")[1].set 4
      click_on "Save"

      click_on "Make a Correction"

      # change the amount on the second item
      # [I'm just replicating the manual test that caught this as close as I can]

      find_all(".numeric")[1].set 6
      find(".btn-success").double_click  # Click_on Save twice did not give the desired fail

      # Re:  fine-tuning the duration below.
      # on CL's local machine:  at 1, it doesn't fail before fixing.  It seems to fairly reliably fair before fixing at 2 ,
      sleep(2.5)

      ii_1 = InventoryItem.where(storage_location: @storage_location, item: item_1).first
      ii_2 = InventoryItem.where(storage_location: @storage_location, item: item_2).first

      # This is where we expect the test to fail, fail, fail if we are in the pre-test situation.  It is showing 90 for ii_1.quantity

      expect(ii_1.quantity).to eq(95)
      expect(ii_2.quantity).to eq(994)
    end
  end
end
