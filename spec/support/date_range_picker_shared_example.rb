def date_range_picker_params(start_date, end_date)
  "#{start_date.to_fs(:date_picker)} - #{end_date.to_fs(:date_picker)}"
end

def date_range_picker_select_range(range_name)
  page.find("#filters_date_range").click
  within ".ranges" do
    page.find("li[data-range-key='#{range_name}']").click
  end
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

  context "when choosing 'Default'" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 7, 31)
      sign_in user
    end

    it "shows only 4 records" do
      visit subject
      expect(page).to have_css("table tbody tr", count: 4)
    end
  end

  context "when choosing 'All Time'" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 7, 31)
      sign_in user
    end

    it "shows all the records" do
      visit subject
      date_range = "#{Time.zone.local(1919, 7, 1).to_fs(:date_picker)} - #{Time.zone.local(2020, 7, 31).to_fs(:date_picker)}"
      fill_in "filters_date_range", with: date_range
      find(:id, 'filters_date_range').native.send_keys(:enter)
      expect(page).to have_css("table tbody tr", count: 6)
    end
  end

  context "when choosing 'Last Month'" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 8, 1)
      sign_in user
    end

    # NOTE: This spec MIGHT be flaky depending on the day of the month.
    # The dates being set may or may not respect the time travelling.
    it "shows only 2 of the records" do
      visit subject
      date_range = "#{Time.zone.local(2019, 7, 1).to_fs(:date_picker)} - #{Time.zone.local(2019, 7, 31).to_fs(:date_picker)}"
      fill_in "filters_date_range", with: date_range
      find(:id, 'filters_date_range').native.send_keys(:enter)
      expect(page).to have_css("table tbody tr", count: 2)
    end
  end

  context "when choosing a date range that only includes the previous week" do
    it "shows only 1 record" do
      visit subject
      date_range = "#{Time.zone.local(2019, 7, 22).to_fs(:date_picker)} - #{Time.zone.local(2019, 7, 28).to_fs(:date_picker)}"
      fill_in "filters_date_range", with: date_range
      find(:id, 'filters_date_range').native.send_keys(:enter)
      expect(page).to have_css("table tbody tr", count: 1)
    end
  end

  context "when entering an invalid date range" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 7, 31)
      sign_in user
    end

    # This test is designed to simulate the case where a user tabs into the date range input field, types in an invalid value,
    # and then presses Enter to submit the form. In the real application:
    # - When the user tabs into the field, the Litepicker.js events (which manage the date range input) don't get triggered.
    # - As a result, invalid data can be sent to the server without the client-side validation taking place.
    #
    # In contrast, if the user clicks on the input field, Litepicker.js would register, validate the input, and reset the
    # value to a default range, preventing invalid data from being submitted.
    #
    # The goal of this test is to ensure that server-side validation works when invalid data is submitted, as it would happen
    # when the user tabs into the input, enters invalid data, and submits the form.
    #
    # However, Capybara's standard methods like `fill_in` or `native.send_keys` trigger the Litepicker.js events, which
    # prevent us from testing this edge case. These methods would cause Litepicker.js to validate the input, reset the
    # value, and prevent invalid data from being submitted to the server.
    #
    # To properly test this case, we use `execute_script` to simulate typing the invalid date directly into the input
    # field, and submitting the form, bypassing the Litepicker.js events entirely.
    it "shows a flash notice and filters results as default" do
      visit subject

      date_range = "nov 08 - feb 08"
      page.execute_script(<<~JS)
        var input = document.getElementById('filters_date_range');
        input.dataset.skipValidation = 'true';
        input.focus();
        input.value = '#{date_range}';
        var form = input.closest('form');
        form.requestSubmit();
      JS

      expect(page).to have_css(".alert.notice", text: "Invalid Date range provided. Reset to default date range")
      expect(page).to have_css("table tbody tr", count: 4)
    end

    # This test is similar to the above but simulates user clicking away from the date range field
    # after having tabbed into it to type something invalid. In this case client side validation
    # via a JavaScript alert should be triggered.
    it "shows a JavaScript alert when user blurs" do
      visit subject

      date_range = "nov 08 - feb 08"
      page.execute_script("document.getElementById('filters_date_range').focus();")
      page.execute_script("document.getElementById('filters_date_range').value = '#{date_range}';")

      accept_alert("Please enter a valid date range (e.g., January 1, 2024 - March 15, 2024).") do
        find('body').click
      end

      valid_date_range = "#{Time.zone.local(2019, 7, 22).to_fs(:date_picker)} - #{Time.zone.local(2019, 7, 28).to_fs(:date_picker)}"
      fill_in "filters_date_range", with: valid_date_range
      find(:id, 'filters_date_range').native.send_keys(:enter)
      expect(page).to have_css("table tbody tr", count: 1)
    end
  end
end
