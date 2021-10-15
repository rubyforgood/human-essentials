require "rails_helper"

describe Exports::ExportReportCSVService do
  describe ".generate_csv_data" do
    context "headers" do
      it "includes the columns provided by the reporter as the first row" do
        expected_headers = %w[First Second]
        reporter = double("reporter", report: { First: "TEST VALUE", Second: "SECOND TEST VALUE" },
                                      columns_for_csv: [:First, :Second])

        result = described_class.new(reporters: [reporter]).generate_csv_data

        expect(result.first).to eq(expected_headers)
      end

      it "humanizes the headers" do
        expected_headers = %w[First\ header Second\ header]
        reporter = double("reporter", report: { first_header: "TEST VALUE",
                                                second_header: "SECOND TEST VALUE" },
                                      columns_for_csv: [:first_header, :second_header])

        result = described_class.new(reporters: [reporter]).generate_csv_data

        expect(result.first).to eq(expected_headers)
      end

      it "ignores keys in the report hash not listed in the columns_for_csv list" do
        expected_headers = %w[First Second]
        reporter = double("reporter", report: { first: "TEST VALUE",
                                                second: "SECOND TEST VALUE",
                                                third: "SKIP THIS ONE" },
                                      columns_for_csv: [:first, :second])

        result = described_class.new(reporters: [reporter]).generate_csv_data

        expect(result.first).not_to include("Third")
        expect(result.first).to eq(expected_headers)
      end
    end

    context "values" do
      it "maps the values from the reporter's report in order of the columns given" do
        expected_values = %w[TEST\ VALUE SECOND\ TEST\ VALUE]
        reporter = double("reporter", report: { first: "TEST VALUE", second: "SECOND TEST VALUE" },
                                      columns_for_csv: [:first, :second])

        result = described_class.new(reporters: [reporter]).generate_csv_data

        expect(result.second).to eq(expected_values)
      end

      it "maps the values in the correct order, based on the columns_for_csv" do
        expected_values = ["But displayed corrected", "Listed out of order this time"]
        reporter = double("reporter", report: { second: "Listed out of order this time",
                                                first: "But displayed corrected" },
                                      columns_for_csv: [:first, :second])

        result = described_class.new(reporters: [reporter]).generate_csv_data

        expect(result.second).to eq(expected_values)
      end

      it "maps the values in the correct order, based on the columns_for_csv" do
        expected_values = ["First value", "second value"]
        reporter = double("reporter", report: { first: "First value",
                                                second: "second value",
                                                third: "Dont include me" },
                                      columns_for_csv: [:first, :second])

        result = described_class.new(reporters: [reporter]).generate_csv_data

        expect(result.second).to eq(expected_values)
        expect(result.second).not_to include("Dont include me")
      end
    end

    context "multiple reports" do
      it "adds additional columns to the end" do
        reporter1 = double("reporter", report: { first: "Never",
                                                 second: "gonna" },
                                       columns_for_csv: [:first, :second])
        reporter2 = double("reporter", report: { third: "give",
                                                 fourth: "you up." },
                                       columns_for_csv: [:third, :fourth])

        result = described_class.new(reporters: [reporter1, reporter2]).generate_csv_data

        expect(result.first).to eq(%w[First Second Third Fourth])
        expect(result.second).to eq(["Never", "gonna", "give", "you up."])
      end
    end
  end
end
