module PartnerReporterService
  REPORT_FOR_DEVELOPMENT = [{ 'type1' => 2, 'type2' => 1 }, %w(1111 2222)].freeze

  def self.partner_types_and_zipcodes(partners:)
    return [] if partners.blank?
    return REPORT_FOR_DEVELOPMENT if Rails.env.development?

    total = {}
    zipcodes = []

    partners.each do |partner|
      partner_agency = DiaperPartnerClient.get(id: partner.id)
      next if partner_agency.blank? || partner_agency[:agency_type].blank?

      agency_type = partner_agency[:agency_type].to_s
      total[agency_type] ||= 0
      total[agency_type] += 1
      zipcodes << partner_agency[:address][:zip_code]
    end

    [total, zipcodes.uniq]
  end
end
