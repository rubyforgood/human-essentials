RSpec.feature "Donations", type: :feature do
  before :each do
    # create an item
  end

  context "When starting a new donation" do
    before(:each) do
      create(:dropoff_location)
      create(:storage_location)
      visit "/donations/new"
    end

    scenario "User can fill out the form to create an in-flight donation" do
      select DropoffLocation.first.name, from: "donation_dropoff_location_id"
      select StorageLocation.first.name, from: "donation_storage_location_id"
      select Donation.new.sources.first, from: "donation_source"

      expect {
        click_button "Create Donation"
      }.to change{Donation.incomplete.count}.by(1)
    end

  end


  context "When working with an in-flight donation" do
    before :each do
      item = create(:item)
      @incomplete = create(:donation, :with_item, item_quantity: 10, item_id: item.id, completed: false)
      # create the incomplete donation
      # add one item to it
      # visit that donation
      visit "/donations/#{@incomplete.id}"
    end

    scenario "a user wants to manually add items" do
      # select an item
      # indicate a quantity
      # add the item to the donation
      # the form should update
      pending("TODO: adding items manually to a donation")
      raise
    end

    scenario "a user wants to remove items from the donation" do
      # click that delete button
      # the form should update
      pending("TODO: removing items from a donation")
      raise
    end

    scenario "a user can change the quantity of a given item in a donation" do
      # change the number in an item field
      # save it
      # the form should update
      pending("TODO: changing quantities in a donation")
      raise
    end

    scenario "a user can complete a donation" do
      click_link "Complete Donation"
      expect(current_path).to eq donations_path
      expect(page.find('.flash')).to have_content('ompleted')
    end

    context "when adding things via barcode" do
      before :each do
        # create one pre-existing barcode associated with an item
        @existing_barcode = create(:barcode_item)
        @item_with_barcode = @existing_barcode.item
        # create a new item that has no barcode existing for it yet
        @item_no_barcode = create(:item)
      end

      scenario "a user can add items via scanning them in by barcode" do
        # enter the barcode into the barcode field
        # the form should update
        pending("TODO: adding items via an existing barcode")
        raise
      end

      scenario "a user can add items that do not yet have a barcode" do
        # enter a new barcode
        # form finds no barcode and responds by prompting user to choose an item and quantity
        # fill that in
        # saves new barcode
        # form updates
        pending "TODO: adding items with a new barcode"
        raise
      end
    end
  end
end
