class AccountRequestMailer < ApplicationMailer
  def confirmation(account_request_id:)
    @account_request = AccountRequest.find(account_request_id)

    mail(
      to: @account_request.email,
      subject: '[Action Required] Human Essential Account Request'
    )
  end

  def approval_request(account_request_id:)
    @account_request = AccountRequest.find(account_request_id)

    mail(
      to: 'info@humanessentials.app',
      subject: "[Account Request] #{@account_request.organization_name}"
    )
  end

  # @param account_request_id [Integer]
  def rejection(account_request_id:)
    @account_request = AccountRequest.find(account_request_id)

    mail(
      to: @account_request.email,
      subject: 'Human Essential Account Request Rejected'
    )
  end
end
