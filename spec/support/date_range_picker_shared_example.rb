def date_range_picker_params(start_date, end_date)
  "#{start_date.to_formatted_s(:date_picker)} - #{end_date.to_formatted_s(:date_picker)}"
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
  let!(:recent) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2019, 7, 24), :organization => organization) }
  let!(:today) { create(described_class.to_s.underscore.to_sym, date_field.to_sym => Time.zone.local(2019, 7, 31), :organization => organization) }

  context "when choosing 'All Time'" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 7, 31)
      sign_in user
    end

    after do
      travel_back
    end

    it "shows all the records" do
      visit subject
      date_range = "#{Time.zone.local(1919, 7, 1).to_formatted_s(:date_picker)} - #{Time.zone.local(2019, 7, 31).to_formatted_s(:date_picker)}"
      fill_in "filters_date_range", with: date_range
      find(:id, 'filters_date_range').native.send_keys(:enter)
      expect(page).to have_css("table tbody tr", count: 3)
    end
  end

  context "when choosing 'Last Month'" do
    before do
      sign_out user
      travel_to Time.zone.local(2019, 8, 1)
      sign_in user
    end

    after do
      travel_back
    end

    # NOTE: This spec MIGHT be flaky depending on the day of the month.
    # The dates being set may or may not respect the time travelling.
    it "shows only 2 of the records" do
      visit subject
      date_range = "#{Time.zone.local(2019, 7, 1).to_formatted_s(:date_picker)} - #{Time.zone.local(2019, 7, 31).to_formatted_s(:date_picker)}"
      fill_in "filters_date_range", with: date_range
      find(:id, 'filters_date_range').native.send_keys(:enter)
      expect(page).to have_css("table tbody tr", count: 2)
    end
  end

  context "when choosing a date range that only includes the previous week" do
    it "shows only 1 record" do
      visit subject
      date_range = "#{Time.zone.local(2019, 7, 22).to_formatted_s(:date_picker)} - #{Time.zone.local(2019, 7, 28).to_formatted_s(:date_picker)}"
      fill_in "filters_date_range", with: date_range
      find(:id, 'filters_date_range').native.send_keys(:enter)
      expect(page).to have_css("table tbody tr", count: 1)
    end
  end
end
