RSpec.describe OrganizationMailer, type: :mailer, skip_seed: true do
  describe "#partner_approval_request" do
    subject { described_class.partner_approval_request(organization: organization, partner: partner) }
    let(:partner) { create(:partner) }
    let(:organization) { partner.organization }

    it "renders the body with correct text with partner information" do
      expect(subject.body.encoded).to include("<h1> You've received a request to approve the account for #{partner.name}. </h1>")
      expect(subject.body.encoded).to include("Review This Organization")
      expect(subject.body.encoded).to include("#{organization.short_name}/partners/#{partner.id}#partner-information\">Review This Organization</a>")
    end

    it "includes a link to the relevant partner" do
      expect(subject.body.encoded).to include("/#{organization.short_name}/partners/#{partner.id}#partner-information")
    end

    it "should be sent to the partner main email with the correct subject line" do
      expect(subject.to).to contain_exactly(organization.email)
      expect(subject.from).to contain_exactly('info@humanessentials.app')
      expect(subject.subject).to eq("[Action Required] Approval requested for #{partner.name}")
    end
  end
end
