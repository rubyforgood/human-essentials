RSpec.describe Reports::PartnerInfoReportService, type: :service do
  let(:year) { 2020 }
  let(:organization) { create(:organization) }
  let(:another_organization) { create(:organization) }

  subject(:report) do
    described_class.new(organization: organization, year: year)
  end

  describe '#report' do
    context "with no partners available" do
      it 'should report zero values' do
        expect(report.report).to eq({
                                      entries: { "Number of Partner Agencies" => 0,
                                                 "Zip Codes Served" => "" },
                                      name: "Partner Agencies and Service Area"
                                    })
      end
    end

    context "with partners available" do
      let!(:p1) do
        create(:partner, :uninvited, organization: organization, name: 'Partner 1') do |p|
          p.profile.update!(zips_served: '90210-1234', agency_type: Partner::AGENCY_TYPES['CAREER'])
        end
      end
      let!(:p2) do
        create(:partner, :uninvited, organization: organization, name: 'Partner 2') do |p|
          p.profile.update!(zips_served: '12345', agency_type: Partner::AGENCY_TYPES['CAREER'])
        end
      end
      let!(:p3) do
        create(:partner, :uninvited, organization: organization, name: 'Partner 3') do |p|
          p.profile.update!(zips_served: '09876-3564', agency_type: Partner::AGENCY_TYPES['EDU'])
        end
      end

      context "with all profiles have zips_served" do
        it 'should report normal values' do
          expect(report.report).to eq({
                                        entries: { "Agency Type: Career technical training" => 2,
                                                   "Agency Type: Education program" => 1,
                                                   "Number of Partner Agencies" => 3,
                                                   "Zip Codes Served" => "09876-3564, 12345, 90210-1234" },
                                        name: "Partner Agencies and Service Area"
                                      })
        end
      end

      context "with some profiles missing zip_served" do
        before { p2.profile.update!(zips_served: nil) }

        it 'should report normal values' do
          expect(report.report).to eq({
                                        entries: { "Agency Type: Career technical training" => 2,
                                                   "Agency Type: Education program" => 1,
                                                   "Number of Partner Agencies" => 3,
                                                   "Zip Codes Served" => "09876-3564, 90210-1234" },
                                        name: "Partner Agencies and Service Area"
                                      })
        end
      end
    end
  end
end
