# frozen_string_literal: true

namespace :organizations do
  namespace :backfill do
    desc 'Backfills partner mailer for organizations with default content'
    task default_email_text: :environment do |task|
      default_email_text = "<div class=\"trix-content\">\n  <div>%{partner_name},<br><br>Your essentials request has been approved and you can find attached to this email a copy of the distribution you will be receiving.<br><br>Your distribution has been set to be <strong>%{delivery_method}</strong> on <strong>%{distribution_date}</strong>.<br><br>See you soon!<br><br>%{comment}</div>\n</div>\n"
      organizations = Organization.joins("INNER JOIN action_text_rich_texts ON action_text_rich_texts.record_id = organizations.id AND record_type = 'Organization'").where("action_text_rich_texts.name = 'default_email_text'")

      organizations.find_each do |organization|
        next unless organization.default_email_text.body.blank?

        organization.default_email_text.update(body: default_email_text)
      end
    end
  end
end
