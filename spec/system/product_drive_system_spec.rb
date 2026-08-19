RSpec.describe "Product Drives", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  include DateRangeHelper

  before do
    sign_in user
  end

  context "When visiting the index page without parameters" do
    let(:subject) { product_drives_path }

    around do |example|
      travel_to Time.zone.local(2019, 7, 1)
      example.run
      travel_back
    end

    before(:each) do
      @product_drives = [
        create(:product_drive, name: "Test name 1", start_date: 3.weeks.ago, end_date: 2.weeks.ago, virtual: true),
        create(:product_drive, name: "Test name 2", start_date: 2.weeks.ago, end_date: 1.week.ago, virtual: false),
        create(:product_drive, name: "Alpha Test name 3", start_date: 1.week.from_now, end_date: 2.weeks.from_now, virtual: false)
      ]
      visit subject
    end

    it "Shows the expected filters with the expected values and in alphabetical order for name filter" do
      expect(page.find("select[name='filters[by_name]']").find(:xpath, 'option[2]').text).to eq "Alpha Test name 3"
      expect(page.has_select?('filters[by_name]', with_options: @product_drives.map(&:name))).to be true
      expect(page).to have_select('filters_date_range_preset', selected: 'Default (recent and upcoming)')
    end

    it "shows the expected product drives" do
      @product_drives.each do |d|
        expect(page).to have_xpath('//table/tbody/tr/td', text: d.name)
        expect(page).to have_xpath('//table/tbody/tr/td', text: d.name)
      end
    end

    # Scoped to the cells rather than counted across the whole page. /Yes/ matched the date
    # filter's "Yesterday" option once the picker became a <select> whose options are page text,
    # and /No/ would match any word containing it just as easily.
    it 'shows only one virtual product drives' do
      expect(page).to have_css('table tbody td', text: 'Yes', exact_text: true, count: 1)
    end

    it 'shows two non-virtual product drives' do
      expect(page).to have_css('table tbody td', text: 'No', exact_text: true, count: 2)
    end

    it 'shows in descending order of start date' do
      expect("Alpha Test name 3").to appear_before("Test name 1")
    end
  end

  context 'when creating a normal product drive' do
    let(:subject) { new_product_drive_path }

    before { visit subject }

    it 'must create a new product drive' do
      expect do
        fill_in 'Name', with: 'Normal 1'
        fill_in 'Start date', with: Time.zone.today
        fill_in 'End date', with: Time.zone.today + 4.hours
        click_button 'Save'
      end.to change(ProductDrive, :count).by(1)
    end

    it 'must have correct attributes' do
      fill_in 'Name', with: 'Normal 1'
      fill_in 'Start date', with: Time.zone.today
      fill_in 'End date', with: Time.zone.today + 1.day
      click_button 'Save'

      expect(ProductDrive.last).to have_attributes({ name: 'Normal 1', start_date: Time.zone.today, end_date: Time.zone.today + 1.day, virtual: false })
    end

    it 'must have the success message' do
      fill_in 'Name', with: 'Virtual 1'
      fill_in 'Start date', with: Time.zone.today
      fill_in 'End date', with: Time.zone.today + 4.hours
      click_button 'Save'

      expect(page.find('[data-flash]')).to have_content('added')
    end
  end

  context 'when creating a Virtual Product Drive' do
    let(:subject) { new_product_drive_path }

    before { visit subject }

    it 'must create a new virtual Product Drive' do
      expect do
        fill_in 'Name', with: 'Virtual 1'
        fill_in 'Start date', with: Time.zone.today
        fill_in 'End date', with: Time.zone.today + 4.hours
        check 'virtual'
        click_button 'Save'
      end.to change(ProductDrive, :count).by(1)
    end

    it 'must have correct attributes' do
      fill_in 'Name', with: 'Virtual 1'
      fill_in 'Start date', with: Time.zone.today
      fill_in 'End date', with: Time.zone.today + 1.day
      check 'virtual'
      click_button 'Save'

      expect(ProductDrive.last).to have_attributes({ name: 'Virtual 1', start_date: Time.zone.today, end_date: Time.zone.today + 1.day, virtual: true })
    end

    it 'must have the success message' do
      fill_in 'Name', with: 'Virtual 1'
      fill_in 'Start date', with: Time.zone.today
      fill_in 'End date', with: Time.zone.today + 4.hours
      check 'virtual'
      click_button 'Save'

      expect(page.find('[data-flash]')).to have_content('added')
    end
  end

  context 'when showing a Product Drive with no end date' do
    let(:new_product_drive) { create(:product_drive, name: 'Endless drive', start_date: 3.weeks.ago, end_date: '') }
    let(:subject) { product_drive_path(new_product_drive.id) }

    it 'must be able to show the product drive' do
      visit subject
      expect(page).to have_content 'Endless drive'
    end
  end
end
