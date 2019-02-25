class UpdateDiaperPartnerJob
  include SuckerPunch::Job
  include DiaperPartnerClient
  workers 2

  def perform(partner_id)
    @partner = Partner.find(partner_id)

    DiaperPartnerClient.post(@partner.attributes) if Flipper.enabled?(:email_active)

    #one line here that checks the post request to see if successful and if so pass to boolean and use that in the if/else below
    #run partner app
    #make post request and see what attributes are required for a successful response
    #figure out what response looks like (in terms of how to read the body of text returned
    #Validate post method throws error when unsuccessful post occurs
    #or add something that does and then see where "post" method is being called and adjust accordingly
#    if
#    {@partner.update(status: "Pending")}
#else
#    @partner.updates(status: )
#
# end
end
