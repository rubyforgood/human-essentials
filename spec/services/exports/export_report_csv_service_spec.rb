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
end
