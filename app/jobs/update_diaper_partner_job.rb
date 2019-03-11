class UpdateDiaperPartnerJob
  include SuckerPunch::Job
  include DiaperPartnerClient
  workers 2

  def perform(partner_id)
    @partner = Partner.find(partner_id)
    ##NEW CODE FROM HERE DOWN
    @response = nil
    @responseCode = nil
    @response = DiaperPartnerClient.post(@partner.attributes) if Flipper.enabled?(:email_active)

    @responseCode = @response.value

    case @responseCode
       when Net::HTTPSuccess
           @partner.update(status: "Pending")
       when Net::HTTPUnauthorized
         @partner.update(status: "Error: Unauthorized Access")
     when Net::HTTPClientError
       @partner.update(status: "Error: Client Error")
     when Net::HTTPServerError
         @partner.update(status: "Error: Server Error")
       else
         @partner.update(status: "Error: Unkown Error")
     end


  end
end
