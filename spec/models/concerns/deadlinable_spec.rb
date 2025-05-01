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
      dummy.public_send("#{field_name}=","")
      expect(dummy).to be_valid
      dummy.public_send("#{field_name}=",nil)
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
      dummy.day_of_month = 29

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:day_of_month, "Reminder day must be between 1 and 28")).to be_truthy

      dummy.day_of_month = -1
      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:day_of_month, "Reminder day must be between 1 and 28")).to be_truthy
    end

    it "validates that day_of_month field is not the same as deadline_day" do
      dummy.by_month_or_week = "day_of_month"
      dummy.deadline_day = 14
      dummy.day_of_month = dummy.deadline_day

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:day_of_month, "Reminder must not be the same as deadline date")).to be_truthy
    end
  end
end
