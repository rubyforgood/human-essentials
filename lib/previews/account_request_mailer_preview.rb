# Provides a preview of a distribution email
class AccountRequestMailerPreview < ActionMailer::Preview
  def confirmation
    ar = AccountRequest.last || FactoryBot.create(:account_request)
    AccountRequestMailer.confirmation(account_request_id: ar.id)
  end

  def approval_request
    ar = AccountRequest.last || FactoryBot.create(:account_request)
    AccountRequestMailer.approval_request(account_request_id: ar.id)
  end
end
