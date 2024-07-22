require "rails_helper"

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

  before do
    dummy.deadline_day = 7
  end

  describe "validations" do
    it do
      is_expected.to validate_numericality_of(:deadline_day)
        .only_integer
        .is_greater_than_or_equal_to(1)
        .is_less_than_or_equal_to(28)
        .allow_nil
    end

    it "validates that the reminder schedule's date fall within the range" do
      schedule.add_recurrence_rule IceCube::Rule.monthly.day_of_month(31)
      dummy.reminder_schedule = schedule.to_ical

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:reminder_schedule, "Reminder day must be between 1 and 28")).to be_truthy
    end

    it "validates that reminder day is not the same as deadline day" do
      schedule.add_recurrence_rule IceCube::Rule.monthly.day_of_month(7)
      dummy.reminder_schedule = schedule.to_ical

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:reminder_schedule, "Reminder must not be the same as deadline date")).to be_truthy
    end
  end
end
