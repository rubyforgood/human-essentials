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

    it 'validates the date field presence if date_or_week_day is "date"' do
      dummy.every_n_months = 1
      dummy.date_or_week_day = "date"
      is_expected.to validate_presence_of(:date)
    end

    it 'validate the day_of_week field presence if date_or_week_day is "week_day"' do
      dummy.every_n_months = 1
      dummy.date_or_week_day = "week_day"
      is_expected.to validate_presence_of(:day_of_week)
      is_expected.to validate_presence_of(:every_nth_day)
    end

    it "validates the date_or_week_day field inclusion" do
      dummy.every_n_months = 1
      is_expected.to validate_inclusion_of(:date_or_week_day).in_array(%w[date week_day])
    end

    it "validates that the reminder schedule's date fall within the range" do
      dummy.every_n_months = 1
      dummy.date_or_week_day = "date"
      dummy.date = 29

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:date, "Reminder day must be between 1 and 28")).to be_truthy
    end

    it "validates that reminder day is not the same as deadline day" do
      dummy.every_n_months = 1
      dummy.date_or_week_day = "date"
      dummy.date = dummy.deadline_day

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:date, "Reminder must not be the same as deadline date")).to be_truthy
    end
  end
end
