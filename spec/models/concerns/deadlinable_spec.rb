RSpec.describe Deadlinable, type: :model do
  let(:dummy_class) do
    Class.new do
      def self.name
        "Dummy"
      end

      include ActiveModel::Model
      include Deadlinable

      attr_accessor :deadline_day, :reminder_day

      def deadline_day?
        !!deadline_day
      end
    end
  end

  subject(:dummy) { dummy_class.new }

  describe "validations" do
    it do
      is_expected.to validate_numericality_of(:deadline_day)
        .only_integer
        .is_greater_than_or_equal_to(1)
        .is_less_than_or_equal_to(28)
        .allow_nil
    end

    it do
      is_expected.to validate_numericality_of(:reminder_day)
        .only_integer
        .is_greater_than_or_equal_to(1)
        .is_less_than_or_equal_to(28)
        .allow_nil
    end

    it "validates that reminder day is not the same as deadline day" do
      dummy.deadline_day = 7
      dummy.reminder_day = 7

      expect(dummy).not_to be_valid
      expect(dummy.errors.added?(:reminder_day, "must be other than 7")).to be_truthy
    end
  end
end
