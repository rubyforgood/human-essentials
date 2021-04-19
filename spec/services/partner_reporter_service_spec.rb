RSpec.describe PartnerReporterService, type: :service do
  describe '::partner_types_and_zipcodes' do
    include_examples 'partner reporter service stubs'
    let(:partner1) { create(:partner) }
    let(:partner2) { create(:partner) }
    let(:partner3) { create(:partner) }

    before do
      results = prepare_results([partner1, partner2, partner3])
      stub_partner_call_result(partner: partner1, results: results)
      stub_partner_call_result(partner: partner2, results: results)
      stub_partner_call_result(partner: partner3, results: results)
    end

    it 'must have the agency types and its numbers' do
      total, _zipcodes = PartnerReporterService.partner_types_and_zipcodes(partners: [partner1, partner2, partner3])
      expect(total).to match({
                               'Family Resource Center' => 2,
                               'Child Abuse Resource Center' => 1
                             })
    end

    it 'must have the zipcodes affecteds' do
      _total, zipcodes = PartnerReporterService.partner_types_and_zipcodes(partners: [partner1, partner2, partner3])
      expect(zipcodes).to match_array(%w(12441 014785))
    end
  end
end
