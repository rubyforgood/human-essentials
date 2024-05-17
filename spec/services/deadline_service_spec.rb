RSpec.describe DeadlineService, type: :service do
  let(:organization) { build_stubbed(:organization, :without_deadlines) }
  let(:partner_group) { build_stubbed(:partner_group, :without_deadlines, organization: organization) }
  let(:partner) { build_stubbed(:partner, organization: organization, partner_group: partner_group) }
  let(:today) { Date.new(2022, 1, 10) }

  around do |example|
    travel_to(today) { example.run }
  end

  shared_examples "calculates the next deadline" do
    subject(:deadline) { described_class.new(partner: partner).next_deadline }

    context "when the deadline is after today" do
      before { expected_receiver[:deadline_day] = 11 }

      it "returns a date within the current month" do
        expect(deadline).to eq today.change(day: 11)
      end
    end

    context "when the deadline is today" do
      before { expected_receiver[:deadline_day] = 10 }

      it "returns a date in the next month" do
        expect(deadline).to eq today.next_month.change(day: 10)
      end
    end

    context "when the deadline is before today" do
      before { expected_receiver[:deadline_day] = 9 }

      it "returns a date in the next month" do
        expect(deadline).to eq today.next_month.change(day: 9)
      end
    end
  end

  describe "#next_deadline" do
    context "do from the partner group" do
      let(:expected_receiver) { partner_group }

      include_examples "calculates the next deadline"
    end

    context "from the organization" do
      let(:expected_receiver) { organization }

      include_examples "calculates the next deadline"
    end
  end
end
