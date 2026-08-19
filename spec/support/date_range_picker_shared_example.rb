# Driving the date range filter.
#
# The control is a preset <select> plus two native date inputs, revealed for the custom case.
# See app/views/shared/_date_range_picker.html.erb. It replaced Litepicker, so the old helpers
# that waited for `.litepicker` and typed a formatted string into a text field are gone --
# there is no text field to type into any more.

def date_range_picker_params(start_date, end_date)
  "#{start_date.to_fs(:date_picker)} - #{end_date.to_fs(:date_picker)}"
end

def select_date_range_preset(name)
  select name, from: "filters_date_range_preset"
end

# Choose an explicit range. "Custom" has to be selected first because that is what reveals the
# two date inputs: until then they carry the `hidden` attribute and Capybara will not fill
# them.
#
# The wait on the hidden field is the important part. filters[date_range] is what actually gets
# submitted, and the Stimulus controller writes it in response to the change event, so clicking
# Filter without waiting is a race. Checking Capybara's #value rather than a [value=...]
# selector because the controller sets the property, which leaves the attribute untouched.
def fill_in_date_range(start_date, end_date)
  select "Custom", from: "filters_date_range_preset"
  fill_in "filters_date_range_start", with: start_date.strftime("%Y-%m-%d")
  fill_in "filters_date_range_end", with: end_date.strftime("%Y-%m-%d")
  expect(page).to have_field("filters_date_range",
    with: date_range_picker_params(start_date, end_date), type: "hidden", visible: :all, wait: 5)
end

RSpec.shared_examples_for "Date Range Picker" do |described_class, date_field|
  before :each do
    date_field ||= "created_at"
    # In case the described class/parent spec has already created instances in a `before` block
    # I'm looking at you, spec/system/request_system_spec.rb:4
    described_class.destroy_all
  end
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  let!(:very_old) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2000, 7, 31), :organization => organization) }
  let!(:two_months_ago) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2019, 5, 31), :organization => organization) }
  let!(:recent) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2019, 7, 24), :organization => organization) }
  let!(:today) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2019, 7, 31), :organization => organization) }
  let!(:one_month_ahead) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2019, 8, 31), :organization => organization) }
  let!(:one_year_ahead) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2020, 7, 31), :organization => organization) }
  let!(:two_years_ahead) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2021, 7, 31), :organization => organization) }

  context "when the page arrives on its default range" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 7, 31)
      sign_in user
    end

    it "shows only 4 records" do
      visit subject
      expect(page).to have_css("table tbody tr", count: 4)
    end

    it "shows the matching preset as selected, with the custom dates put away" do
      visit subject
      expect(page).to have_select("filters_date_range_preset", selected: "Default (recent and upcoming)")
      expect(page).to have_no_field("filters_date_range_start")
    end
  end

  context "when choosing a preset" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 7, 31)
      sign_in user
    end

    # The preset dates are computed by the server, in Time.zone, which is the whole reason they
    # moved off the browser -- so travelling in time here genuinely exercises them.
    it "filters to that preset and stays selected afterwards" do
      visit subject
      select_date_range_preset "Today"
      click_on "Filter"

      expect(page).to have_css("table tbody tr", count: 1)
      expect(page).to have_select("filters_date_range_preset", selected: "Today")
    end
  end

  context "when choosing a range that covers everything" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 7, 31)
      sign_in user
    end

    it "shows all the records" do
      visit subject
      fill_in_date_range(Time.zone.local(1919, 7, 1), Time.zone.local(2020, 7, 31))
      click_on "Filter"
      expect(page).to have_css("table tbody tr", count: 6)
    end
  end

  context "when choosing last month" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 8, 1)
      sign_in user
    end

    # NOTE: This spec MIGHT be flaky depending on the day of the month.
    # The dates being set may or may not respect the time travelling.
    it "shows only 2 of the records" do
      visit subject
      fill_in_date_range(Time.zone.local(2019, 7, 1), Time.zone.local(2019, 7, 31))
      click_on "Filter"
      expect(page).to have_css("table tbody tr", count: 2)
    end
  end

  context "when choosing a date range that only includes the previous week" do
    it "shows only 1 record" do
      visit subject
      fill_in_date_range(Time.zone.local(2019, 7, 22), Time.zone.local(2019, 7, 28))
      click_on "Filter"
      expect(page).to have_css("table tbody tr", count: 1)
    end

    it "comes back as a custom range rather than snapping to a preset" do
      visit subject
      fill_in_date_range(Time.zone.local(2019, 7, 22), Time.zone.local(2019, 7, 28))
      click_on "Filter"

      expect(page).to have_select("filters_date_range_preset", selected: "Custom")
      expect(page).to have_field("filters_date_range_start", with: "2019-07-22")
      expect(page).to have_field("filters_date_range_end", with: "2019-07-28")
    end
  end

  context "when the end date is before the start date" do
    # The old control accepted free text, so this had to be caught by a window.alert() on blur.
    # Native date inputs cannot hold a non-date, which leaves exactly one way to build an
    # invalid range, and the controller reports it in the page and blocks the submit.
    it "says so in the page and does not filter" do
      visit subject
      select "Custom", from: "filters_date_range_preset"
      fill_in "filters_date_range_start", with: "2019-09-01"
      fill_in "filters_date_range_end", with: "2019-08-01"

      expect(page).to have_css("[role='alert']", text: "The end date must be on or after the start date.")

      click_on "Filter"
      expect(page).to have_css("[role='alert']", text: "The end date must be on or after the start date.")
      expect(page).to have_field("filters_date_range_end", with: "2019-08-01")
    end
  end

  context "when an invalid date range reaches the server anyway" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 7, 31)
      sign_in user
    end

    # No longer reachable through the control -- there is no text field to mistype into -- but
    # filters[date_range] is still a URL parameter, so the server's guard has to hold. This is
    # the case a bookmark or a hand-edited link produces.
    it "shows a flash notice and filters results as default" do
      visit "#{subject}?#{{filters: {date_range: "nov 08 - feb 08"}}.to_query}"

      expect(page).to have_css("[data-flash='notice']", text: "Invalid Date range provided. Reset to default date range")
      expect(page).to have_css("table tbody tr", count: 4)
    end
  end
end
