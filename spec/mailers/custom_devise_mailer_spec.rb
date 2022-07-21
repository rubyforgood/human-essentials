RSpec.describe CustomDeviseMailer, type: :mailer, skip_seed: true do
  describe "#invitation_instructions" do
    let(:partner_user) { create(:partner_user) }
    let(:mail) { described_class.invitation_instructions(partner_user, SecureRandom.uuid) }

    context "when partner is invited" do
      let(:partner_user) { build(:partner_user) }

      it "invites to primary user" do
        expect(mail.subject).to eq("You've been invited to be a partner with #{partner_user.partner.organization.name}")
        expect(mail.html_part.body).to include("You've been invited to become a partner organization with <strong>#{partner_user.partner.organization.name}!</strong>")
      end
    end

    context "when invited by other partner users" do
      let(:partner) { create(:partner) }
      let(:partner_user) { create(:partner_user, partner: partner.profile) }

      it "invites to partner user" do
        expect(mail.subject).to eq("You've been invited to #{partner_user.partner.name}'s partnerbase account")
        expect(mail.html_part.body).to include("You've been invited to <strong>#{partner_user.partner.name}'s</strong> account for requesting items from <strong>#{partner_user.partner.organization.name}!")
      end
    end
  end
end
