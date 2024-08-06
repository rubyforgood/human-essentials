RSpec.describe DistributionMailer, type: :mailer do
  let(:organization) { create(:organization, name: "TEST ORG") }
  let(:user) { create(:user, organization: organization) }
  let(:partner) { create(:partner, name: 'PARTNER', organization_id: organization.id) }
  let(:distribution) { create(:distribution, organization: user.organization, comment: "Distribution comment", partner: partner) }
  let(:request) { create(:request, distribution: distribution) }

  let(:pick_up_email) { 'pick_up@org.com' }

  before do
    organization.default_email_text = "Default email text example\n\n%{delivery_method} %{distribution_date}\n\n%{partner_name}\n\n%{comment}"
    organization.update!(email: "me@org.com")
    request
    allow(DistributionPdf).to receive(:new).and_return(double('DistributionPdf', compute_and_render: ''))
    allow(partner.profile).to receive(:pick_up_email).and_return(pick_up_email)
  end

  describe "#partner_mailer" do
    let(:distribution_changes) { {} }
    let(:mail) { DistributionMailer.partner_mailer(organization, distribution, 'test subject', distribution_changes) }

    it "renders the body with organization's email text" do
      expect(mail.body.encoded).to match("Default email text example")
      expect(mail.html_part.body).to match(%(From: <a href="mailto:me@org.com">me@org.com</a>))
      expect(mail.to).to eq([distribution.request.user_email])
      expect(mail.cc).to eq([distribution.partner.email, pick_up_email])
      expect(mail.from).to eq(["no-reply@humanessentials.app"])
      expect(mail.subject).to eq("test subject from TEST ORG")
    end

    it "renders the body with distributions text" do
      expect(mail.body.encoded).to match("Distribution comment")
      expect(mail.subject).to eq("test subject from TEST ORG")
    end

    context "with deliver_method: :pick_up" do
      let(:mail) do
        distribution = create(:distribution, organization: user.organization, comment: "Distribution comment", partner: partner, delivery_method: :pick_up)
        DistributionMailer.partner_mailer(organization, distribution, 'test subject', distribution_changes)
      end

      it "renders the body with 'picked up' specified" do
        expect(mail.body.encoded).to match("picked up")
      end

      context 'when parners profile pick_up_email is present' do
        it 'sends email to the primary contact and partner`s pickup person' do
          expect(mail.cc.first).to match(partner.email)
          expect(mail.cc.second).to match(pick_up_email)
        end

        context 'when pickup person happens to be the same as the primary contact' do
          let(:pick_up_email) { partner.email }

          it 'does not send email twice' do
            expect(mail.cc.count).to eq(1)
            expect(mail.cc.first).to match(partner.email)
          end
        end
      end
    end

    context "with deliver_method: :delivery" do
      let(:mail) {
        distribution = create(:distribution, organization: user.organization, comment: "Distribution comment", partner: partner, delivery_method: :delivery)
        DistributionMailer.partner_mailer(organization, distribution, 'test subject', distribution_changes)
      }

      it "renders the body with 'delivered' specified" do
        expect(mail.body.encoded).to match("delivered")
      end

      it 'sends copy of email only to the partner' do
        expect(mail.cc).to match([partner.email])
      end
    end

    context "with distribution changes" do
      let(:distribution_changes) do
        {
          removed: [
            { name: "Adult Diapers" }
          ],
          updates: [
            {
              name: "Kid Diapers",
              new_quantity: 4,
              old_quantity: 100
            }
          ]
        }
      end

      it "renders the body with changes that happened in the distribution" do
        distribution = create(:distribution, organization: user.organization, comment: "Distribution comment", partner: partner, delivery_method: :delivery)
        mail = DistributionMailer.partner_mailer(organization, distribution, 'test subject', distribution_changes)
        expect(mail.body.encoded).to match(distribution_changes[:removed][0][:name])
        expect(mail.body.encoded).to match(distribution_changes[:updates][0][:name])
      end
    end
  end

  describe "#reminder_email" do
    let(:mail) { DistributionMailer.reminder_email(distribution.id) }

    context 'HTML format' do
      it "renders the body with organization's email text" do
        html = html_body(mail)
        expect(html).to match("This is a friendly reminder")
        expect(html).to match(%(For more information: <a href="mailto:me@org.com">me@org.com</a>))
        expect(mail.to).to eq([distribution.request.user_email])
        expect(mail.cc).to eq([distribution.partner.email])
        expect(mail.from).to eq(["no-reply@humanessentials.app"])
        expect(mail.subject).to eq("PARTNER Distribution Reminder")
      end
    end

    context 'Text format' do
      it "renders the body with organization's email text" do
        text = text_body(mail)
        expect(text).to match("This is a friendly reminder")
        expect(text).to match(%(For more information: me@org.com))
        expect(mail.from).to eq(["no-reply@humanessentials.app"])
        expect(mail.subject).to eq("PARTNER Distribution Reminder")
      end
    end

    context "with deliver_method: :pick_up" do
      it "renders the body with 'pick up' specified" do
        distribution = create(:distribution, organization: user.organization, comment: "Distribution comment", partner: partner, delivery_method: :pick_up)
        mail = DistributionMailer.reminder_email(distribution.id)
        expect(mail.body.encoded).to match("pick up")
      end
    end

    context "with deliver_method: :delivery" do
      it "renders the body with 'delivery' specified" do
        distribution = create(:distribution, organization: user.organization, comment: "Distribution comment", partner: partner, delivery_method: :delivery)
        mail = DistributionMailer.reminder_email(distribution.id)
        expect(mail.body.encoded).to match("delivery")
      end
    end
  end
end
