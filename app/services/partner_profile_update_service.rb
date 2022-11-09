class PartnerProfileUpdateService
  include ServiceObjectErrorsMixin

  def initialize(old_partner, new_partner_params)
    @partner = old_partner
    @params = new_partner_params
    @old_partner_counties = old_partner.partner_counties
  end

  def call
    @partner.partner_counties.each(&:destroy!)
    @partner.reload

    @partner.assign_attributes(@params)
    return false unless counties_are_valid?

    @partner.reload # I'm not sure why I need to reload it *Again* but I seem to. CLF 20221109

    @partner.update @params

    @partner.valid? # Returns true if no errors
  end

  def counties_are_valid?
    total_share = 0
    @params["partner_counties_attributes"].each do |pc|
      total_share += pc[1]["client_share"].to_i
    end

    is_good = (total_share == 0 || total_share == 100)

    @partner.errors.add(:base, "client share % must total to 0 or 100") unless is_good
    is_good
  end
end
