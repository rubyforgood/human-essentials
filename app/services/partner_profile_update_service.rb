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
    return false unless valid?


    @partner.reload
    # Replace the current partner with the new parameters

    @partner.update @params

    @partner.valid? # Returns true if no errors
  end

  def valid?
    pca = @params["partner_counties_attributes"]
    total_share = 0
    pca.each do | pc |
      cs = pc[1]["client_share"].to_i
      total_share = total_share + cs
    end
    puts "total client_share is #{total_share}"

    is_good = (total_share == 0 || total_share == 100)

    @partner.errors.add(:base, 'client share % must total to 0 or 100') unless is_good
    is_good
  end

end
