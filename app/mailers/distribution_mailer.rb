# This mailer is for correspondence about Distributions; primarily for notifying Partners about pending distributions
class DistributionMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.distribution_mailer.partner_mailer.subject
  #
  def partner_mailer(current_organization, distribution, subject, distribution_changes)
    @distribution = distribution
    @partner = @distribution.partner

    return if @distribution.past? || @partner.deactivated?

    default_email_text = current_organization.default_email_text
    @default_email_text_interpolated = interpolate_custom_text(@distribution, default_email_text)

    @from_email = current_organization.email.presence || current_organization.users.first.email
    @distribution_changes = distribution_changes
    pdf = DistributionPdf.new(current_organization, @distribution).compute_and_render
    attachments[format("%s %s.pdf", @partner.name, @distribution.created_at.strftime("%Y-%m-%d"))] = pdf
    cc = [@partner.email]
    cc.push(@partner.profile&.pick_up_email) if @distribution.pick_up?
    cc.compact!
    cc.uniq!

    mail(to: requestee_email(@distribution), cc: cc, subject: "#{subject} from #{current_organization.name}")
  end

  def reminder_email(distribution_id)
    @distribution = Distribution.find(distribution_id)
    @partner = @distribution.partner

    return if @distribution.past? || !@partner.send_reminders || @partner.deactivated?

    @custom_reminder_interpolated = interpolate_custom_text(@distribution, @distribution.custom_reminder)

    mail(to: requestee_email(@distribution), cc: @partner.email, subject: "#{@partner.name} Distribution Reminder")
  end

  private

  def interpolate_custom_text(distribution, custom_text)
    TextInterpolatorService.new(custom_text.body.to_s, {
                                                          delivery_method: distribution.delivery? ? 'delivered' : 'picked up',
                                                          distribution_date: distribution.issued_at.strftime("%m/%d/%Y"),
                                                          partner_name: distribution.partner.name,
                                                          comment: distribution.comment
                                                        }).call
  end

  def requestee_email(distribution)
    distribution.request ? distribution.request.user_email : @partner.email
  end
end
