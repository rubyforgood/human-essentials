RSpec.describe ReminderScheduleService, type: :service do
  let(:day_of_month_schedule) {
    ReminderScheduleService.new({
      by_month_or_week: "day_of_month",
      day_of_month: 10
    })
  }
  let(:day_of_week_schedule) {
    ReminderScheduleService.new({
      by_month_or_week: "day_of_week",
      day_of_week: 0,
      every_nth_day: 1
    })
  }
  let(:empty_schedule) { ReminderScheduleService.new({}) }

  describe "initialize" do
    let(:subject) {
      ReminderScheduleService.new({
        by_month_or_week: "day_of_month",
        day_of_month: 10
      })
    }

    it "returns a ReminderScheduleService instance" do
      expect(subject).to be_a_kind_of(ReminderScheduleService)
      expect(subject.day_of_month).to eq 10
    end
  end

  describe "from_ical" do
    let(:subject) {
      ReminderScheduleService.from_ical(
        "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=10"
      )
    }

    it "returns a ReminderScheduleService instance" do
      expect(subject).to be_a_kind_of(ReminderScheduleService)
      expect(subject.day_of_month).to eq 10
    end

    it "returns nil if a blank or invalid ical string is provided", :aggregate_failures do
      expect(ReminderScheduleService.from_ical(nil)).to be_nil
      expect(ReminderScheduleService.from_ical("")).to be_nil
      expect(ReminderScheduleService.from_ical("notanicalstring")).to be_nil
    end

    it "returns nil if the provided ical string defines no schedule rules" do
      expect(ReminderScheduleService.from_ical("DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\n")).to be_nil
    end
  end

  describe "assign_attributes" do
    it "updates the ReminderScheduleService's attributes", :aggregate_failures do
      empty_schedule.assign_attributes({
        by_month_or_week: "day_of_week",
        day_of_week: 0,
        every_nth_day: 1
      })

      expect(empty_schedule.by_month_or_week).to eq "day_of_week"
      expect(empty_schedule.day_of_week).to eq 0
      expect(empty_schedule.every_nth_day).to eq 1
    end
  end

  describe "to_icecube_schedule" do
    it "returns an IceCube::Schedule instance" do
      result = day_of_month_schedule.to_icecube_schedule
      expect(result).to be_a_kind_of(IceCube::Schedule)
    end

    it "returns nil if the ReminderScheduleService isn't valid" do
      expect(ReminderScheduleService.new({}).to_icecube_schedule).to eq nil
    end
  end

  describe "to_ical" do
    it "returns ical string representation of a day_of_month schedule" do
      travel_to Time.zone.local(2020, 10, 10)
      expect(day_of_month_schedule.to_ical).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYMONTHDAY=10"
    end

    it "returns ical string representation of a day_of_week schedule" do
      travel_to Time.zone.local(2020, 10, 10)
      expect(day_of_week_schedule.to_ical).to eq "DTSTART;TZID=#{Time.zone.now.zone}:20201010T000000\nRRULE:FREQ=MONTHLY;BYDAY=1SU"
    end

    it "returns nil if the ReminderScheduleService isn't valid" do
      expect(empty_schedule.to_icecube_schedule).to eq nil
    end
  end

  describe "show_description" do
    it "returns textual description of a day_of_month schedule" do
      expect(day_of_month_schedule.show_description).to eq "Monthly on the 10th day of the month"
    end

    it "returns textual description of a day_of_week schedule" do
      expect(day_of_week_schedule.show_description).to eq "Monthly on the 1st Sunday"
    end

    it "returns nil if the ReminderScheduleService isn't valid" do
      expect(empty_schedule.to_icecube_schedule).to eq nil
    end
  end

  describe "fields_filled_out?" do
    it "returns false if all fields are nil" do
      expect(empty_schedule.fields_filled_out?).to be false
    end

    it "returns true otherwise", :aggregate_failures do
      empty_schedule.by_month_or_week = "day_of_month"
      expect(empty_schedule.fields_filled_out?).to be true
      expect(day_of_month_schedule.fields_filled_out?).to be true
      expect(day_of_week_schedule.fields_filled_out?).to be true
    end
  end

  describe "occurs_on?" do
    before do
      travel_to Time.zone.local(2020, 1, 10)
    end

    context "with a day_of_month schedule" do
      let(:subject) { day_of_month_schedule }

      it "returns true if the schedule occurs on the provided date", :aggregate_failures do
        expect(subject.occurs_on?(Time.zone.local(2020, 10, 10))).to be true
        expect(subject.occurs_on?(Time.zone.local(2020, 11, 10))).to be true
        expect(subject.occurs_on?(Time.zone.local(2020, 12, 10))).to be true
      end

      it "returns false otherwise", :aggregate_failures do
        expect(subject.occurs_on?(Time.zone.local(2020, 10, 1))).to be false
        expect(subject.occurs_on?(Time.zone.local(2020, 11, 9))).to be false
        expect(subject.occurs_on?(Time.zone.local(2020, 12, 11))).to be false
      end
    end

    context "with a day_of_week schedule" do
      let(:subject) { day_of_week_schedule }

      it "returns true if the schedule occurs on the provided date", :aggregate_failures do
        expect(subject.occurs_on?(Time.zone.local(2020, 2, 2))).to be true
        expect(subject.occurs_on?(Time.zone.local(2020, 3, 1))).to be true
        expect(subject.occurs_on?(Time.zone.local(2020, 4, 5))).to be true
      end

      it "returns false otherwise", :aggregate_failures do
        expect(subject.occurs_on?(Time.zone.local(2020, 2, 3))).to be false
        expect(subject.occurs_on?(Time.zone.local(2020, 3, 2))).to be false
        expect(subject.occurs_on?(Time.zone.local(2020, 4, 4))).to be false
      end
    end

    it "returns nil if the ReminderScheduleService isn't valid" do
      expect(empty_schedule.to_icecube_schedule).to eq nil
    end
  end

  describe "validations" do
    it "validates by_month_or_week is one of the accepted strings", :aggregate_failures do
      day_of_month_schedule.by_month_or_week = "other_string"
      expect(day_of_month_schedule).not_to be_valid
      day_of_month_schedule.by_month_or_week = "day_of_month"
      expect(day_of_month_schedule).to be_valid
      day_of_month_schedule.by_month_or_week = nil
      expect(day_of_month_schedule).not_to be_valid

      day_of_week_schedule.by_month_or_week = "other_string"
      expect(day_of_week_schedule).not_to be_valid
      day_of_week_schedule.by_month_or_week = "day_of_week"
      expect(day_of_week_schedule).to be_valid
      day_of_week_schedule.by_month_or_week = nil
      expect(day_of_week_schedule).not_to be_valid
    end

    context "on a day_of_month schedule" do
      let(:subject) { day_of_month_schedule }

      it "validates that day_of_month falls within range" do
        (1..28).step(1) do |n|
          subject.day_of_month = n
          expect(subject).to be_valid
        end
        subject.day_of_month = -1
        expect(subject).not_to be_valid
        subject.day_of_month = 29
        expect(subject).not_to be_valid
        subject.day_of_month = nil
        expect(subject).not_to be_valid
      end

      it "skips validating day_of_week_is_within_range" do
        subject.day_of_week = -1
        expect(subject).to be_valid
        subject.day_of_week = 7
        expect(subject).to be_valid
        subject.day_of_week = nil
        expect(subject).to be_valid
      end

      it "skips validating every_nth_day_is_within_range" do
        subject.every_nth_day = 0
        expect(subject).to be_valid
        subject.every_nth_day = 5
        expect(subject).to be_valid
        subject.every_nth_day = nil
        expect(subject).to be_valid
      end
    end

    context "on a day_of_week schedule" do
      let(:subject) { day_of_week_schedule }

      it "validates day_of_week falls within range" do
        (0..6).step(1) do |n|
          subject.day_of_week = n
          expect(subject).to be_valid
        end
        subject.day_of_week = -1
        expect(subject).not_to be_valid
        subject.day_of_week = 7
        expect(subject).not_to be_valid
        subject.day_of_week = nil
        expect(subject).not_to be_valid
      end

      it "validates every_nth_day falls within range" do
        (1..4).step(1) do |n|
          subject.every_nth_day = n
          expect(subject).to be_valid
        end
        subject.every_nth_day = -1
        expect(subject).to be_valid
        subject.every_nth_day = 0
        expect(subject).not_to be_valid
        subject.every_nth_day = 5
        expect(subject).not_to be_valid
        subject.every_nth_day = nil
        expect(subject).not_to be_valid
      end

      it "skips validating day_of_month" do
        subject.day_of_month = nil
        expect(subject).to be_valid
        subject.day_of_month = -1
        expect(subject).to be_valid
        subject.day_of_month = 29
        expect(subject).to be_valid
      end
    end
  end
end
