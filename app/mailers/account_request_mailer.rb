class AccountRequestMailer < ApplicationMailer

  def confirmation(account_request_id:)
    @account_request = AccountRequest.find(account_request_id)

    mail(
      to: @account_request.email,
      subject: '[Action Required] Diaperbase Account Request'
    )
  end

end
