require "rails_helper"
require Rails.root.join("lib/quality/report")

RSpec.describe Quality::Report do
  subject(:report) { described_class.new(measurements: measurements, thresholds: thresholds) }

  let(:thresholds) do
    {
      "coverage" => {"line_min" => 80.0, "branch_min" => 80.0},
      "flog" => {"method_max" => 100.0, "class_max" => 200.0},
      "mutation" => {"kill_ratio_min" => 90.0},
      "brakeman" => {"warnings_max" => 5},
      "rubocop" => {"offenses_max" => 0}
    }
  end

  let(:measurements) do
    {
      coverage: {line: 85.0, branch: 82.0},
      flog: {method_max: 40.0, class_max: 150.0},
      mutation: {kill_ratio: 95.0},
      brakeman: {warnings: 2},
      rubocop: {offenses: 0}
    }
  end

  describe "#passed?" do
    context "when all measurements meet their thresholds" do
      it "returns true" do
        expect(report).to be_passed
      end
    end

    context "when a measurement is below a minimum threshold" do
      let(:measurements) { super().merge(coverage: {line: 50.0, branch: 82.0}) }

      it "returns false" do
        expect(report).not_to be_passed
      end
    end

    context "when a measurement exceeds a maximum threshold" do
      let(:measurements) { super().merge(flog: {method_max: 150.0, class_max: 150.0}) }

      it "returns false" do
        expect(report).not_to be_passed
      end
    end

    context "when a measurement is missing" do
      let(:measurements) { super().merge(mutation: {}) }

      it "returns false" do
        expect(report).not_to be_passed
      end
    end

    context "when a threshold is missing" do
      let(:thresholds) { super().merge("rubocop" => {}) }

      it "returns false" do
        expect(report).not_to be_passed
      end
    end
  end

  describe "#to_s" do
    it "includes the header" do
      expect(report.to_s).to include("Quality gates")
    end

    it "includes each gate name" do
      output = report.to_s
      expect(output).to include("Line coverage")
      expect(output).to include("Branch coverage")
      expect(output).to include("Flog max (method)")
      expect(output).to include("Mutation kill ratio")
      expect(output).to include("Brakeman warnings")
      expect(output).to include("RuboCop offenses")
    end

    it "shows the pass count" do
      expect(report.to_s).to include("7/7 gates passed.")
    end

    context "when a measurement is missing" do
      let(:measurements) { super().merge(mutation: {}) }

      it "renders n/a" do
        expect(report.to_s).to include("n/a")
      end

      it "shows the failing pass count" do
        expect(report.to_s).to include("6/7 gates passed.")
      end
    end

    context "with whole-number measurements" do
      let(:measurements) do
        super().merge(brakeman: {warnings: 5})
      end

      it "renders them without decimals" do
        expect(report.to_s).to include("5 <= 5")
      end
    end
  end
end
