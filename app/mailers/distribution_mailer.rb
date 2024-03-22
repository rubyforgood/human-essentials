# This mailer is for correspondence about Distributions; primarily for notifying Partners about pending distributions
class DistributionMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.distribution_mailer.partner_mailer.subject
  #
  def partner_mailer(current_organization, distribution, subject, distribution_changes)
    return if distribution.past? || distribution.partner.deactivated?

    @partner = distribution.partner
    @distribution = distribution
    @comment = distribution.comment
    requestee_email = distribution.request ? distribution.request.user_email : @partner.email

    delivery_method = @distribution.delivery? ? 'delivered' : 'picked up'
    @default_email_text = current_organization.default_email_text
    @default_email_text_interpolated = TextInterpolatorService.new(@default_email_text.body.to_s, {
                                                                     delivery_method: delivery_method,
                                                                     distribution_date: @distribution.issued_at.strftime("%m/%d/%Y"),
                                                                     partner_name: @partner.name,
                                                                     comment: @comment
                                                                   }).call

    @from_email = current_organization.email.presence || current_organization.users.first.email
    @distribution_changes = distribution_changes
    pdf = DistributionPdf.new(current_organization, @distribution).compute_and_render
    attachments[format("%s %s.pdf", @partner.name, @distribution.created_at.strftime("%Y-%m-%d"))] = pdf
    cc = [@partner.email]
    cc.push(@partner.profile&.pick_up_email) if distribution.pick_up?
    cc.compact!
    cc.uniq!

    mail(to: requestee_email, cc: cc, subject: "#{subject} from #{current_organization.name}")
  end

  def reminder_email(distribution_id)
    distribution = Distribution.find(distribution_id)
    @partner = distribution.partner
    @distribution = distribution
    requestee_email = distribution.request ? distribution.request.user_email : @partner.email

    return if @distribution.past? || !@partner.send_reminders || @partner.deactivated?

    mail(to: requestee_email, cc: @partner.email, subject: "#{@partner.name} Distribution Reminder")
  end
end
