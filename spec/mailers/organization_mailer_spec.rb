RSpec.describe OrganizationMailer, type: :mailer do
  describe "#partner_approval_request" do
    subject { described_class.partner_approval_request(organization: organization, partner: partner) }
    let(:partner) { create(:partner) }
    let(:organization) { partner.organization }

    it "renders the body with correct text with partner information" do
      html = html_body(subject)
      expect(html).to include("<h1> You've received a request to approve the account for #{partner.name}. </h1>")
      expect(html).to include("Review This Organization")
      expect(html).to include("#{organization.short_name}/partners/#{partner.id}#partner-information\">Review This Organization</a>")
      text = text_body(subject)
      expect(text).to include("You've received a request to approve the account for #{partner.name}.")
      expect(text).to include("Review This Organization")
      expect(text).to include("#{organization.short_name}/partners/#{partner.id}#partner-information")
    end

    it "includes a link to the relevant partner" do
      expect(subject.body.encoded).to include("/#{organization.short_name}/partners/#{partner.id}#partner-information")
    end

    it "should be sent to the partner main email with the correct subject line" do
      expect(subject.to).to contain_exactly(organization.email)
      expect(subject.from).to contain_exactly('no-reply@humanessentials.app')
      expect(subject.subject).to eq("[Action Required] Approval requested for #{partner.name}")
    end
  end
end
