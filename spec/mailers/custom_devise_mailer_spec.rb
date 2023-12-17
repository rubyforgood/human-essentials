RSpec.describe CustomDeviseMailer, type: :mailer do
  describe "#invitation_instructions" do
    let(:user) { create(:partner_user) }
    let(:mail) { described_class.invitation_instructions(user, SecureRandom.uuid) }

    context "when partner is invited" do
      let(:partner) do
        partner = create(:partner, :uninvited)
        partner.primary_user.delete
        partner.reload
        partner
      end

      let(:user) do
        create(:partner_user, partner: partner)
      end

      it "invites to primary user" do
        expect(mail.subject).to eq("You've been invited to be a partner with #{user.partner.organization.name}")
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
      let(:user) { create(:user) }

      it "invites to user" do
        expect(mail.subject).to eq("Your Human Essentials App Account Approval")
        expect(mail.html_part.body).to include("Your request has been approved and you're invited to become an user of the Human Essentials inventory management system!")
      end

      it "has invite expiration message" do
        expect(mail.html_part.body).to include("For security reasons these invitations expire. This invitation will expire in 8 hours or if a new password reset is triggered.")
      end
    end
  end
end
