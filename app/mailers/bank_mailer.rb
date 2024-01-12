# app/mailers/bank_mailer.rb

class BankMailer < ApplicationMailer
  def notify_request_submission(partner_request)
    @partner_request = partner_request
    mail(to: @partner_request.bank.contact_email, subject: 'Partner Request Submitted')
  end
end
