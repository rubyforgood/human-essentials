RSpec.describe Deadlinable, type: :model do
  let(:dummy_class) do
    Class.new do
      def self.name
        "Dummy"
      end

      include ActiveModel::Model
      include Deadlinable

      attr_accessor :deadline_day, :reminder_schedule

      def deadline_day?
        !!deadline_day
      end
    end
  end

  subject(:dummy) { dummy_class.new }
  let(:current_day) { Time.current }
  let(:schedule) { IceCube::Schedule.new(current_day) }

  shared_examples "doesn't validate absent field" do |field_name|
    it "doesn't validate the #{field_name} field when it isn't present" do
      dummy.public_send(:"#{field_name}=", "")
      expect(dummy).to be_valid
      dummy.public_send(:"#{field_name}=", nil)
      expect(dummy).to be_valid
    end
  end

  describe "validations" do
    it "validates the deadline_day field" do
      dummy.deadline_day = nil
      expect(dummy).to be_valid
      dummy.deadline_day = 1
      expect(dummy).to be_valid
      dummy.deadline_day = 28
      expect(dummy).to be_valid
      dummy.deadline_day = 0.1
      expect(dummy).not_to be_valid
      dummy.deadline_day = -1
      expect(dummy).not_to be_valid
      dummy.deadline_day = 50
      expect(dummy).not_to be_valid
    end

    it "validates the by_month_or_week field" do
      dummy.by_month_or_week = "day_of_month"
      expect(dummy).to be_valid
      dummy.by_month_or_week = "day_of_week"
      expect(dummy).to be_valid
      dummy.by_month_or_week = "other_string"
      expect(dummy).not_to be_valid
    end

    include_examples "doesn't validate absent field", "by_month_or_week"

    it "validates the day_of_week field" do
      (0..6).step(1) do |day|
        dummy.day_of_week = day.to_s
        expect(dummy).to be_valid
      end
      dummy.day_of_week = "-1"
      expect(dummy).not_to be_valid
      dummy.day_of_week = "7"
      expect(dummy).not_to be_valid
      dummy.day_of_week = "other_string"
      expect(dummy).not_to be_valid
    end

    include_examples "doesn't validate absent field", "day_of_week"

    it "validates the every_nth_day field" do
      (1..4).step(1) do |n|
        dummy.every_nth_day = n.to_s
        expect(dummy).to be_valid
      end
      dummy.every_nth_day = "-1"
      expect(dummy).to be_valid
      dummy.every_nth_day = "6"
      expect(dummy).not_to be_valid
      dummy.every_nth_day = "other_string"
      expect(dummy).not_to be_valid
    end

    include_examples "doesn't validate absent field", "every_nth_day"

    it "validates the every_nth_month field" do
      (1..12).step(1) do |n|
        dummy.every_nth_month = n.to_s
        expect(dummy).to be_valid
      end
      dummy.every_nth_month = "-1"
      expect(dummy).not_to be_valid
      dummy.every_nth_month = "24"
      expect(dummy).not_to be_valid
      dummy.every_nth_month = "other_string"
      expect(dummy).not_to be_valid
    end

    include_examples "doesn't validate absent field", "every_nth_month"

    it "validates that day_of_month field falls within the range" do
      dummy.by_month_or_week = "day_of_month"
      dummy.day_of_month = "29"

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:day_of_month, "Reminder day must be between 1 and 28")).to be_truthy

      dummy.day_of_month = "-1"
      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:day_of_month, "Reminder day must be between 1 and 28")).to be_truthy
    end

    it "validates that day_of_month field is not the same as deadline_day" do
      dummy.by_month_or_week = "day_of_month"
      dummy.deadline_day = 14
      dummy.day_of_month = "14"

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:day_of_month, "Reminder must not be the same as deadline date")).to be_truthy
    end
  end

  it "convert_to_reminder_schedule returns by month day schedule in ICAL format" do
    travel_to Time.zone.local(2020, 10, 10)
    expect(dummy.convert_to_reminder_schedule(10)).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=10"
  end

  it "show_description returns textual description of rule in ICAL format" do
    ical_schedule = "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=10"
    expect(dummy.show_description(ical_schedule)).to eq "Monthly on the 10th day of the month"
  end

  it "get_values_from_reminder_schedule sets deadlineable's start_date to today if there is no schedule" do
    dummy.get_values_from_reminder_schedule
    expect(dummy.start_date).to eq(Time.zone.today)
    dummy.reminder_schedule = "notavalidschedule"
    dummy.get_values_from_reminder_schedule
    expect(dummy.start_date).to eq(Time.zone.today)
  end

  context "with an existing day_of_month schedule" do
    before do
      dummy.reminder_schedule = "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=10"
    end

    it "get_values_from_reminder_schedule sets deadlineable's fields with values stored in ICAL schedule" do
      dummy.get_values_from_reminder_schedule
      expect(dummy.start_date).to eq(Time.zone.local(2020, 10, 10))
      expect(dummy.by_month_or_week).to eq("day_of_month")
      expect(dummy.day_of_month).to eq(10)
      expect(dummy.day_of_week).to eq(nil)
      expect(dummy.every_nth_day).to eq(nil)
      expect(dummy.every_nth_month).to eq(1)
    end
  end

  context "with an existing day_of_week schedule" do
    before do
      dummy.reminder_schedule = "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYDAY=3WE"
    end

    it "get_values_from_reminder_schedule sets deadlineable's fields with values stored in ICAL schedule" do
      dummy.get_values_from_reminder_schedule
      expect(dummy.start_date).to eq(Time.zone.local(2020, 10, 10))
      expect(dummy.by_month_or_week).to eq("day_of_week")
      expect(dummy.day_of_month).to eq(nil)
      expect(dummy.day_of_week).to eq(3)
      expect(dummy.every_nth_day).to eq(3)
      expect(dummy.every_nth_month).to eq(1)
    end
  end

  context "by day of month" do
    before do
      dummy.by_month_or_week = "day_of_month"
    end

    context "with a specified start date" do
      before do
        dummy.start_date = "2020/10/10"
      end

      it "create_schedule returns schedule in ICAL format" do
        dummy.day_of_month = "10"
        dummy.every_nth_month = "1"
        expect(dummy.create_schedule).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=10"
        dummy.day_of_month = "15"
        dummy.every_nth_month = "3"
        expect(dummy.create_schedule).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=15"
      end
    end

    context "without a specified start date" do
      before do
        travel_to Time.zone.local(2020, 11, 11)
      end

      it "create_schedule returns schedule in ICAL format" do
        dummy.day_of_month = "10"
        dummy.every_nth_month = "1"
        expect(dummy.create_schedule).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201111T000000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=10"
        dummy.day_of_month = "15"
        dummy.every_nth_month = "3"
        expect(dummy.create_schedule).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201111T000000\nRRULE:FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=15"
      end
    end

    it "create_schedule returns nil if needed fields are missing" do
      dummy.day_of_month = "10"
      expect(dummy.create_schedule).to eq nil
      dummy.day_of_month = nil
      dummy.every_nth_month = "1"
      expect(dummy.create_schedule).to eq nil
    end
  end

  context "by day of week" do
    before do
      dummy.by_month_or_week = "day_of_week"
    end

    context "with a specified start date" do
      before do
        dummy.start_date = "2020/10/10"
      end

      it "create_schedule returns schedule in ICAL format" do
        dummy.day_of_week = "0"
        dummy.every_nth_day = "1"
        dummy.every_nth_month = "1"
        expect(dummy.create_schedule).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYDAY=1SU"
        dummy.day_of_week = "3"
        dummy.every_nth_day = "3"
        dummy.every_nth_month = "1"
        expect(dummy.create_schedule).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYDAY=3WE"
      end
    end

    context "without a specified start date" do
      before do
        travel_to Time.zone.local(2020, 11, 11)
      end

      it "create_schedule returns schedule in ICAL format" do
        dummy.day_of_week = "0"
        dummy.every_nth_day = "1"
        dummy.every_nth_month = "1"
        expect(dummy.create_schedule).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201111T000000\nRRULE:FREQ=MONTHLY;BYDAY=1SU"
        dummy.day_of_week = "3"
        dummy.every_nth_day = "3"
        dummy.every_nth_month = "1"
        expect(dummy.create_schedule).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201111T000000\nRRULE:FREQ=MONTHLY;BYDAY=3WE"
      end
    end

    it "create_schedule returns nil if needed fields are missing" do
      dummy.day_of_week = "0"
      dummy.every_nth_day = "1"
      expect(dummy.create_schedule).to eq nil
      dummy.every_nth_day = nil
      dummy.every_nth_month = "1"
      expect(dummy.create_schedule).to eq nil
      dummy.day_of_week = nil
      dummy.every_nth_day = "1"
      expect(dummy.create_schedule).to eq nil
    end
  end
end
