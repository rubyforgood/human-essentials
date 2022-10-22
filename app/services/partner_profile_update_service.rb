class PartnerProfileUpdateService
  include ServiceObjectErrorsMixin

  def initialize(old_partner, new_partner_params)
    @partner = old_partner
    @params = new_partner_params
    @old_partner_counties = old_partner.partner_counties
  end

  def call
    @partner.update(@params)

    @partner.partner_counties.each(&:destroy!)
    @partner.reload
    # Replace the current distribution with the new parameters

    @partner.update @params

    @partner.valid?  # Returns true if no errors
  end

end
