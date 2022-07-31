RSpec.describe CustomDeviseMailer, type: :mailer, skip_seed: true do
  describe "#invitation_instructions" do
    let(:user) { create(:user) }
    let(:mail) { described_class.invitation_instructions(user, SecureRandom.uuid) }

    context "when partner is invited" do
      let(:partner) do
        partner = create(:partner, :uninvited)
        partner.profile.primary_user.delete
        partner.profile.reload
        partner
      end

      let(:user) { create(:user, partner: partner.profile) }

      it "invites to primary user" do
        expect(mail.subject).to eq("You've been invited to be a partner with #{user.partner.organization.name}")
        # expect(mail.html_part.body).to include("You've been invited to become a partner organization with <strong>#{user.partner.organization.name}!</strong>")
      end
    end

    context "when invited by other partner users" do
      let(:partner) { create(:partner) }
      let(:user) { create(:user, partner: partner.profile) }

      it "invites to partner user" do
        expect(mail.subject).to eq("You've been invited to #{user.partner.name}'s partnerbase account")
        # expect(mail.html_part.body).to include("You've been invited to <strong>#{user.partner.name}'s</strong> account for requesting items from <strong>#{user.partner.organization.name}!")
      end
    end
  end
end
