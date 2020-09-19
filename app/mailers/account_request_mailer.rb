class AccountRequestMailer < ApplicationMailer
  def confirmation(account_request_id:)
    @account_request = AccountRequest.find(account_request_id)

    mail(
      to: @account_request.email,
      subject: '[Action Required] Diaperbase Account Request'
    )
  end

  def approval_request(account_request_id:)
    @account_request = AccountRequest.find(account_request_id)

    mail(
      to: 'info@diaper.app',
      subject: "[Account Request] #{@account_request.organization_name}"
    )
  end
end
