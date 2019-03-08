RSpec.describe DistributionMailer, type: :mailer do
  let(:mail) { DistributionMailer.partner_mailer(@organization, @distribution) }
  before do
    @organization.default_email_text = "Default email text example"
    @distribution = create(:distribution, organization: @user.organization, comment: "Distribution comment")
  end

  let(:mail) { DistributionMailer.partner_mailer(@organization, @distribution) }

  it "renders the body with organizations email text" do
    expect(mail.body.encoded).to match("Default email text example")
  end

  it "renders the body with distributions text" do
    expect(mail.body.encoded).to match("Distribution comment")
  end
end