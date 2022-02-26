RSpec.describe "Product Drives", type: :system, js: true, skip_seed: true do
  include DateRangeHelper

  before do
    sign_in @user
    @url_prefix = "/#{@organization.id}"
  end

  context "When visiting the index page without parameters" do
    let(:subject) { @url_prefix + "/diaper_drives" }

    around do |example|
      travel_to Time.zone.local(2019, 7, 1)
      example.run
      travel_back
    end

    before(:each) do
      @diaper_drives = [
        create(:diaper_drive, name: "Test name 1", start_date: 3.weeks.ago, end_date: 2.weeks.ago, virtual: true),
        create(:diaper_drive, name: "Test name 2", start_date: 2.weeks.ago, end_date: 1.week.ago, virtual: false)
      ]
      visit subject
    end

    it "Shows the expected filters with the expected values" do
      expect(page.has_select?('filters_by_name', with_options: @diaper_drives.map(&:name))).to be true
      expect(page.has_field?('filters_date_range', with: this_year))
    end

    it "shows the expected product drives" do
      @diaper_drives.each do |d|
        expect(page).to have_xpath('//table/tbody/tr/td', text: d.name)
        expect(page).to have_xpath('//table/tbody/tr/td', text: d.name)
      end
    end

    it 'shows only one virtual product drive' do
      expect(page).to have_text(/Yes/, maximum: 1)
    end

    it 'shows only one non-virtual product drive' do
      expect(page).to have_text(/No/, maximum: 1)
    end
  end

  context 'when creating a normal Product Drive' do
    let(:subject) { @url_prefix + "/diaper_drives/new" }

    before { visit subject }

    it 'must create a new Product Drive' do
      expect do
        fill_in 'Name', with: 'Normal 1'
        fill_in 'Start Date', with: Time.zone.today
        fill_in 'End Date', with: Time.zone.today + 4.hours
        click_button 'Create Product Drive'
      end.to change(DiaperDrive, :count).by(1)
    end

    it 'must have correct attributes' do
      fill_in 'Name', with: 'Normal 1'
      fill_in 'Start Date', with: Time.zone.today
      fill_in 'End Date', with: Time.zone.today + 1.day
      click_button 'Create Product Drive'

      expect(DiaperDrive.last).to have_attributes({ name: 'Normal 1', start_date: Time.zone.today, end_date: Time.zone.today + 1.day, virtual: false })
    end

    it 'must have the success message' do
      fill_in 'Name', with: 'Virtual 1'
      fill_in 'Start Date', with: Time.zone.today
      fill_in 'End Date', with: Time.zone.today + 4.hours
      click_button 'Create Product Drive'

      expect(page.find('.alert')).to have_content('added')
    end
  end

  context 'when creating a Virtual Product Drive' do
    let(:subject) { @url_prefix + "/diaper_drives/new" }

    before { visit subject }

    it 'must create a new virtual Product Drive' do
      expect do
        fill_in 'Name', with: 'Virtual 1'
        fill_in 'Start Date', with: Time.zone.today
        fill_in 'End Date', with: Time.zone.today + 4.hours
        check 'virtual'
        click_button 'Create Product Drive'
      end.to change(DiaperDrive, :count).by(1)
    end

    it 'must have correct attributes' do
      fill_in 'Name', with: 'Virtual 1'
      fill_in 'Start Date', with: Time.zone.today
      fill_in 'End Date', with: Time.zone.today + 1.day
      check 'virtual'
      click_button 'Create Product Drive'

      expect(DiaperDrive.last).to have_attributes({ name: 'Virtual 1', start_date: Time.zone.today, end_date: Time.zone.today + 1.day, virtual: true })
    end

    it 'must have the success message' do
      fill_in 'Name', with: 'Virtual 1'
      fill_in 'Start Date', with: Time.zone.today
      fill_in 'End Date', with: Time.zone.today + 4.hours
      check 'virtual'
      click_button 'Create Product Drive'

      expect(page.find('.alert')).to have_content('added')
    end
  end
end
