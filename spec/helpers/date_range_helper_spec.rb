RSpec.describe DateRangeHelper, type: :helper do
  context "when parsing date range params" do
    it "should return the default date value" do
      expect(date_range_params).to eq(default_date)
    end
  end

  context "when creating a date interval using selected_interval" do
    it "should return the correct date interval using the default date" do
      expect(selected_interval).to eq([2.months.ago.to_date, 1.month.from_now.to_date])
    end

    it "should throw a Date::Error when input is invalid" do
      allow_any_instance_of(DateRangeHelper).to receive(:default_date).and_return("nov 08 to feb 08")
      expect { selected_interval }.to raise_error(Date::Error, "invalid date")
    end
  end
end
