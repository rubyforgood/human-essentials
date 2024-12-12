RSpec.describe Reports::SummaryReportService, type: :service do
  let(:organization) { create(:organization) }
  let(:another_organization) { create(:organization) }
  let(:year) { 2020 }

  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  describe '#report' do
    it 'should report zero values' do
      expect(report.report).to eq({
                                    entries: { "% difference in yearly donations" => "0%",
                                               "% difference in total money donated" => "0%",
                                               "% difference in disposable diaper donations" => "0%" },
                                    name: "Year End Summary"
                                  })
    end

    context 'when the organization has items' do
      let(:organization) { create(:organization, :with_items) }

      it 'should report positive values' do
        disposable_item = organization.items.disposable.first
        non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

        last_year = year - 1
        this_year_time = Time.zone.parse("#{year}-05-31 14:00:00")
        last_year_time = Time.zone.parse("#{last_year}-05-31 14:00:00")

        donations = create_list(:donation, 6,
          issued_at: this_year_time,
          money_raised: 3000,
          organization: organization)

        donations += create_list(:donation, 2,
          product_drive: nil,
          issued_at: last_year_time,
          money_raised: 1000,
          organization: organization)

        donations.each do |donation|
          create_list(:line_item, 3, :donation, quantity: 20, item: disposable_item, itemizable: donation)
          create_list(:line_item, 3, :donation, quantity: 10, item: non_disposable_item, itemizable: donation)
        end

        expect(report.report).to eq({
          entries: { "% difference in yearly donations" => "+200%",
                     "% difference in total money donated" => "+800%",
                     "% difference in disposable diaper donations" => "+200%" },
          name: "Year End Summary"
        })
      end

      it 'should report negative values' do
        disposable_item = organization.items.disposable.first
        non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

        last_year = year - 1
        this_year_time = Time.zone.parse("#{year}-05-31 14:00:00")
        last_year_time = Time.zone.parse("#{last_year}-05-31 14:00:00")

        donations = create_list(:donation, 2,
          issued_at: this_year_time,
          money_raised: 3000,
          organization: organization)

        donations += create_list(:donation, 6,
          product_drive: nil,
          issued_at: last_year_time,
          money_raised: 1000,
          organization: organization)

        donations.each do |donation|
          create_list(:line_item, 3, :donation, quantity: 20, item: disposable_item, itemizable: donation)
          create_list(:line_item, 3, :donation, quantity: 10, item: non_disposable_item, itemizable: donation)
        end

        expect(report.report).to eq({
          entries: { "% difference in yearly donations" => "-67%",
                     "% difference in total money donated" => "0%",
                     "% difference in disposable diaper donations" => "-67%" },
          name: "Year End Summary"
        })
      end
    end
  end
end
