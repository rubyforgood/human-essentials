# Default Mailer Info
class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@humanessentials.app"
  layout "mailer"
end
