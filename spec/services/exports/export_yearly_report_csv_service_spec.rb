RSpec.describe Exports::ExportYearlyReportCSVService do
  describe ".generate_csv_data" do
    it "creates CSV data including headers" do
      yearly_reports = [
        [
          {
            "entries" => {
              "Year" => 2023
            }
          },
          {
            "entries" => {
              "First" => 1,
              "Second" => 2
            }
          }
        ],
        [
          {
            "entries" => {
              "Year" => 2024
            }
          },
          {
            "entries" => {
              "First" => 5,
              "Second" => 10
            }
          }
        ]
      ]

      result = described_class.new(yearly_reports:).generate_csv_data

      expect(result.first).to eq(%w[Year First Second])
      expect(result.last).to eq([2024, 5, 10])
    end

    it "creates a CSV string" do
      yearly_reports = [
        [
          {
            "entries" => {
              "Year" => 2023
            }
          },
          {
            "entries" => {
              "First" => 1,
              "Second" => 2
            }
          }
        ],
        [
          {
            "entries" => {
              "Year" => 2024
            }
          },
          {
            "entries" => {
              "First" => 5,
              "Second" => 10
            }
          }
        ]
      ]

      result = described_class.new(yearly_reports:).generate_csv
      expected_result = <<~CSV
        Year,First,Second
        2023,1,2
        2024,5,10
      CSV
      expect(result).to eq(expected_result)
    end
  end
end
