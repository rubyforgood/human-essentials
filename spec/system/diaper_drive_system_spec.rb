RSpec.describe "Diaper Drives", type: :system, js: true do
  include DateRangeHelper

  before do
    sign_in @user
    @url_prefix = "/#{@organization.id}"
  end

  context "When visiting the index page without parameters" do
    let(:subject) { @url_prefix + "/diaper_drives" }

    before(:each) do
      @diaper_drives = [
        create(:diaper_drive, name: "Test name 1", start_date: 3.weeks.ago, end_date: 2.weeks.ago),
        create(:diaper_drive, name: "Test name 2", start_date: 2.weeks.ago, end_date: 1.week.ago)
      ]
      visit subject
    end

    it "Shows the expected filters with the expected values" do
      expect(page.has_select?('filters_by_name', with_options: @diaper_drives.map(&:name))).to be true
      expect(page.has_field?('filters_date_range', with: this_year))
    end

    it "shows the expected diaper drives" do
      @diaper_drives.each do |d|
        expect(page).to have_xpath('//table/tbody/tr/td', text: d.name)
        expect(page).to have_xpath('//table/tbody/tr/td', text: d.name)
      end
    end
  end
end
