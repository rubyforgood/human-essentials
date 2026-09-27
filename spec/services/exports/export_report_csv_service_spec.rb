RSpec.describe Exports::ExportReportCSVService do
  describe ".generate_csv_data" do
    it "creates CSV data including headers" do
      report = {
        'entries' => {
          'First' => 5,
          'Second' => 10
        }
      }

      result = described_class.new(reports: [report]).generate_csv_data

      expect(result.first).to eq(%w(First Second))
      expect(result.last).to eq([5, 10])
    end

    it 'creates a CSV string' do
      report = {
        'entries' => {
          'First' => 5,
          'Second' => 10
        }
      }

      result = described_class.new(reports: [report]).generate_csv
      expected_result = <<~CSV
        First,Second
        5,10
      CSV
      expect(result).to eq(expected_result)
    end
  end

  describe ".generate_csv with range: true" do
    it "creates a CSV string with a Year column and one row per report" do
      report2023 = AnnualReport.new(year: 2023, all_reports: [
        {'name' => 'Section A', 'entries' => {'First' => 5, 'Second' => 10}},
        {'name' => 'Section B', 'entries' => {'Third' => 15}}
      ])
      report2024 = AnnualReport.new(year: 2024, all_reports: [
        {'name' => 'Section A', 'entries' => {'First' => 6, 'Second' => 11}},
        {'name' => 'Section B', 'entries' => {'Third' => 16}}
      ])

      result = described_class.new(reports: [report2023, report2024]).generate_csv(range: true)
      expected_result = <<~CSV
        Year,First,Second,Third
        2023,5,10,15
        2024,6,11,16
      CSV
      expect(result).to eq(expected_result)
    end

    it "aligns values by header and leaves blanks when years have different columns" do
      # Older reports may predate fields that were added later (and vice
      # versa), so each value must line up under its own header.
      report2023 = AnnualReport.new(year: 2023, all_reports: [
        {'name' => 'Section A', 'entries' => {'First' => 5, 'Retired Field' => 99}}
      ])
      report2024 = AnnualReport.new(year: 2024, all_reports: [
        {'name' => 'Section A', 'entries' => {'First' => 6, 'New Field' => 42}}
      ])

      result = described_class.new(reports: [report2023, report2024]).generate_csv(range: true)
      expected_result = <<~CSV
        Year,First,Retired Field,New Field
        2023,5,99,
        2024,6,,42
      CSV
      expect(result).to eq(expected_result)
    end

    it "creates an empty CSV when there are no reports" do
      result = described_class.new(reports: []).generate_csv(range: true)

      expect(result).to eq("")
    end
  end
end
