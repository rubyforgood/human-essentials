class PartnerRequestController < ApplicationController
  def create
    @partner_request = PartnerRequest.new(partner_request_params)

    if @partner_request.save
      BankMailer.notify_request_submission(@partner_request).deliver_now
      redirect_to root_path, notice: 'Partner request submitted successfully.'
    else
      render :new
    end
  end
end
