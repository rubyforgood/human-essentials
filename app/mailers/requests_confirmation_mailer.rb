class RequestsConfirmationMailer < ApplicationMailer
  def confirmation_email(request)
    @organization = request.organization
    @partner = request.partner
    @item_requests = request.item_requests.includes(:item)
    requester = request.requester
    @requester_user_name = requester.is_a?(User) ? requester.name : nil # Requester can be the partner, if no user is specified
    # If the organization has opted in to receiving an email when a request is made, CC them
    cc = [@partner.email]
    if @organization.receive_email_on_requests
      cc.push(@organization.email)
    end
    cc.flatten!
    cc.compact!
    cc.uniq!
    mail(to: requester.email, cc: cc, subject: "#{@organization.name} - Requests Confirmation")
  end
end
