# Default Mailer Info
class ApplicationMailer < ActionMailer::Base
  default from: "Please do not reply to this email as this mail box is not monitored — Human Essentials <no-reply@humanessentials.app>"
  layout "mailer"
end
