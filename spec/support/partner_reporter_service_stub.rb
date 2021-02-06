shared_examples_for "partner reporter service stubs" do
  def stub_partner_call_result(partner:, results:)
    allow(DiaperPartnerClient).to receive(:get).with(id: partner.id).and_return(results.find { |r| r[:diaper_partner_id] == partner.id })
  end

  def prepare_results(partners)
    partner_agencies = []
    agency_types = ['Family Resource Center', 'Family Resource Center', 'Child Abuse Resource Center', 'Some kind of type']
    zipcodes = %w(12441 014785 014785 3457100)

    partners.each do |partner|
      partner_agencies << {
        diaper_partner_id: partner.id,
        agency_type: agency_types.shift,
        address: {
          zip_code: zipcodes.shift
        }
      }
    end

    partner_agencies
  end
end
