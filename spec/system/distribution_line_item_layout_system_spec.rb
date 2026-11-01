RSpec.describe "Distribution line item layout", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization:) }
  let(:partner) { create(:partner, organization:, name: "Layout Partner") }
  let(:storage_location) { create(:storage_location, organization:, name: "Layout Storage") }
  let(:item) { create(:item, organization:, name: "Layout Diapers") }

  before do
    sign_in(user)
    TestInventory.create_inventory(organization, storage_location.id => {item.id => 100})
  end

  shared_examples "responsive line items" do
    it "keeps each label with its field at narrow and desktop widths" do
      select "Layout Storage", from: "From storage location"
      expect(page).to have_css("#__add_line_item:not(.disabled)")
      [375, 600, 1200].each do |width|
        current_window.resize_to(width, 900)
        expect(page).to have_css(".li-name .select2-container")

        layout = page.evaluate_script(<<~JS)
          (() => {
            const row = document.querySelector('.distribution-line-item-inputs');
            const bounds = element => element.getBoundingClientRect();
            const fields = [...row.children];
            return {
              labelsFit: fields.every(field => {
                const label = field.querySelector('label, .form-label');
                const text = document.createRange();
                text.selectNodeContents(label);
                return bounds(label).height < parseFloat(getComputedStyle(label).fontSize) * 2 &&
                  label.scrollWidth <= field.clientWidth + 1 &&
                  bounds(text).left >= bounds(field).left - 1 &&
                  bounds(text).right <= bounds(field).right + 1;
              }),
              gridFitsViewport: bounds(row).left >= 0 &&
                bounds(row).right <= document.documentElement.clientWidth + 1,
              fieldsFit: fields.every(field => bounds(field).left >= bounds(row).left &&
                bounds(field).right <= bounds(row).right + 1),
              labelsAlign: fields.every(field => {
                const label = field.querySelector('label, .form-label');
                const value = field.querySelector('.select2-container, input, .distribution-requested-value');
                return Math.abs(bounds(label).left - bounds(value).left) <= 1 &&
                  bounds(label).bottom <= bounds(value).top + 1;
              }),
              dropdownFits: bounds(row.querySelector('.select2-container')).width <=
                bounds(row.querySelector('.li-name')).width + 1
            };
          })()
        JS

        expect(layout).to eq("labelsFit" => true, "gridFitsViewport" => true, "fieldsFit" => true, "labelsAlign" => true, "dropdownFits" => true)
      end

      current_window.resize_to(375, 900)
      click_on "Add Another Item"
      expect(page).to have_css(".distribution-line-item-inputs", count: 2)
      within all(".distribution-line-item-inputs").last do
        expect(page).to have_field("Item")
        fill_in "Quantity - Total Units", with: "5"
        expect(page).to have_field("Quantity - Total Units", with: "5")
        find(".select2-selection").click
      end
      find(".select2-results__option", text: "Layout Diapers").click
      within all(".line_item_section").last do
        expect(page).to have_content("Layout Diapers")
        click_on "Remove"
      end
      expect(page).to have_css(".distribution-line-item-inputs", count: 1)
    end
  end

  context "on a regular distribution" do
    before { visit new_distribution_path }

    include_examples "responsive line items"
  end

  context "when fulfilling a request" do
    before do
      request = create(:request, organization:, partner:, request_items: [{"item_id" => item.id, "quantity" => 10}])
      create(:item_request, request:, item:, quantity: 10)
      visit request_path(request)
      click_on "Fulfill request"
    end

    include_examples "responsive line items"
  end
end
