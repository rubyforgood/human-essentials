RSpec.describe CustomDeviseMailer, type: :mailer do
  describe "#invitation_instructions" do
    let(:user) { create(:partner_user) }
    let(:mail) { described_class.invitation_instructions(user, SecureRandom.uuid) }

    context "when partner is invited" do
      let(:partner) do
        partner = create(:partner, :uninvited)
        partner.primary_user.delete
        partner.organization.update!(invitation_text: "Custom Invitation Text")
        partner.reload
        partner
      end

      let(:user) do
        create(:partner_user, partner: partner)
      end

      it "invites to primary user" do
        expect(mail.subject).to eq("You've been invited to be a partner with #{user.partner.organization.name}")
        expect(mail.html_part.body).to include(partner.organization.invitation_text)
        expect(mail.html_part.body).to include("You've been invited to become a partner with <strong>#{user.partner.organization.name}!</strong>")
      end
    end

    context "when other partner users invited" do
      let(:partner) { create(:partner) }
      let(:user) { create(:partner_user, partner: partner) }

      it "invites to partner user" do
        expect(mail.subject).to eq("You've been invited to #{user.partner.name}'s Human Essentials account")
        expect(mail.html_part.body).to include("You've been invited to <strong>#{user.partner.name}'s</strong> account for requesting items from <strong>#{user.partner.organization.name}!")
      end
    end

    context "when user is invited" do
      let(:invitation_sent_at) { Time.zone.now }
      let(:user) { create(:user, invitation_sent_at: invitation_sent_at) }

      it "invites to user" do
        expect(mail.subject).to eq("Your Human Essentials App Account Approval")
        expect(mail.html_part.body).to include("Your request has been approved and you're invited to become an user of the Human Essentials inventory management system!")
      end

      it "has invite expiration message and reset instructions" do
        expect(mail.html_part.body).to include("This invitation will expire at #{user.invitation_due_at.strftime("%B %d, %Y %I:%M %p")} GMT or if a new password reset is triggered.")
      end

      it "has reset instructions" do
        expect(mail.html_part.body).to match(%r{<p>If your invitation has an expired message, go <a href="http://.+?/users/password/new">here</a> and enter your email address to reset your password.</p>})
        expect(mail.html_part.body).to include("Feel free to ignore this email if you are not interested or if you feel it was sent by mistake.")
      end
    end
  end
end
