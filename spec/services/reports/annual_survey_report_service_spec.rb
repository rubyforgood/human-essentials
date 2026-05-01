RSpec.describe Reports::AnnualSurveyReportService, type: :service do
  let(:organization) { create(:organization) }

  subject(:service) do
    described_class.new(organization: organization, year_start: year_start, year_end: year_end)
  end

  describe "#call" do
    context "with a valid year range" do
      let(:year_start) { 2020 }
      let(:year_end) { 2022 }

      let(:report_2020) { instance_double(AnnualReport) }
      let(:report_2021) { instance_double(AnnualReport) }
      let(:report_2022) { instance_double(AnnualReport) }

      before do
        allow(Reports).to receive(:retrieve_report)
          .with(hash_including(year: 2020)).and_return(report_2020)
        allow(Reports).to receive(:retrieve_report)
          .with(hash_including(year: 2021)).and_return(report_2021)
        allow(Reports).to receive(:retrieve_report)
          .with(hash_including(year: 2022)).and_return(report_2022)
      end

      it "returns one report per year in the range" do
        expect(service.call).to eq([report_2020, report_2021, report_2022])
      end

      it "calls retrieve_report with recalculate: true for each year" do
        service.call
        expect(Reports).to have_received(:retrieve_report)
          .with(hash_including(organization: organization, year: 2020, recalculate: true))
        expect(Reports).to have_received(:retrieve_report)
          .with(hash_including(organization: organization, year: 2021, recalculate: true))
        expect(Reports).to have_received(:retrieve_report)
          .with(hash_including(organization: organization, year: 2022, recalculate: true))
      end
    end

    context "with a single year range" do
      let(:year_start) { 2021 }
      let(:year_end) { 2021 }

      let(:report_2021) { instance_double(AnnualReport) }

      before do
        allow(Reports).to receive(:retrieve_report)
          .with(hash_including(year: 2021)).and_return(report_2021)
      end

      it "returns a single report" do
        expect(service.call).to eq([report_2021])
      end
    end

    context "when a year's report raises ActiveRecord::RecordInvalid" do
      let(:year_start) { 2020 }
      let(:year_end) { 2022 }

      let(:report_2020) { instance_double(AnnualReport) }
      let(:report_2022) { instance_double(AnnualReport) }

      before do
        allow(Reports).to receive(:retrieve_report)
          .with(hash_including(year: 2020)).and_return(report_2020)
        allow(Reports).to receive(:retrieve_report)
          .with(hash_including(year: 2021)).and_raise(ActiveRecord::RecordInvalid)
        allow(Reports).to receive(:retrieve_report)
          .with(hash_including(year: 2022)).and_return(report_2022)
      end

      it "skips the failed year and returns the remaining reports" do
        expect(service.call).to eq([report_2020, report_2022])
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error)
        service.call
        expect(Rails.logger).to have_received(:error).with(/Failed to retrieve annual report for year 2021/)
      end
    end
  end
end
