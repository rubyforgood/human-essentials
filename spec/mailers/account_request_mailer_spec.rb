RSpec.describe AccountRequestMailer, type: :mailer do
  describe '#confirmation' do
    let(:mail) { AccountRequestMailer.confirmation(account_request_id: account_request_id) }
    let(:account_request_id) { account_request.id }
    let(:account_request) { FactoryBot.create(:account_request) }

    context 'when the account_request_id provided does not match any AccountRequest' do
      let(:account_request_id) { 0 }

      it 'should trigger raise a ActiveRecord::RecordNotFound error' do
        expect { mail.body }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it 'should be sent to the specified account_request email' do
      expect(mail.to).to eq([account_request.email])
    end

    it 'should be from no-reply@humanessentials.app' do
      expect(mail.from).to eq(['no-reply@humanessentials.app'])
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq('[Action Required] Human Essential Account Request')
    end

    context 'HTML format' do
      it 'should include the staging/demo account information' do
        html = html_body(mail)
        expect(html).to match(%r{<a href='https://staging.humanessentials.app/users/sign_in'>Human Essentials</a>})
        expect(html).to match('Username: org_admin1@example.com')
        expect(html).to match('Password: password!')

        expect(html).to match('Username: verified@example.com')
        expect(html).to match('Password: password!')
      end

      it 'should include the instruction video link' do
        expect(html_body(mail)).to include('https://youtu.be/w53iaJtlQUo')
      end

      it 'should include the button to confirm the request' do
        expect(html_body(mail)).to include(
          confirmation_account_requests_url(token: account_request.identity_token)
        )
      end
    end

    context 'Text format' do
      it 'should include the staging/demo account information' do
        text = text_body(mail)
        expect(text).to match(%r{https://staging.humanessentials.app/users/sign_in})
        expect(text).to match('Username: org_admin1@example.com')
        expect(text).to match('Password: password!')

        expect(text).to match('Username: verified@example.com')
        expect(text).to match('Password: password!')
      end

      it 'should include the instruction video link' do
        expect(text_body(mail)).to include('https://youtu.be/w53iaJtlQUo')
      end

      it 'should include the button to confirm the request' do
        expect(text_body(mail)).to include(
          confirmation_account_requests_url(token: account_request.identity_token)
        )
      end
    end
  end

  describe '#approval_request' do
    let(:mail) { AccountRequestMailer.approval_request(account_request_id: account_request_id) }
    let(:account_request_id) { account_request.id }
    let(:account_request) { FactoryBot.create(:account_request) }

    context 'when the account_request_id provided does not match any AccountRequest' do
      let(:account_request_id) { 0 }

      it 'should trigger raise a ActiveRecord::RecordNotFound error' do
        expect { mail.body }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it 'should be sent to the info@humanessentials.app email address' do
      expect(mail.to).to eq(['info@humanessentials.app'])
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq("[Account Request] #{account_request.organization_name}")
    end

    it 'should include details of the account request' do
      account_request.attributes.each do |ar, value|
        expect(mail.body.encoded).to include(ar.humanize)
        expect(mail.body.encoded).to include(value.to_s)
      end
    end

    it 'should include the admin link to create the new organization from the account request' do
      expect(mail.body.encoded).to include(
        new_admin_organization_url(token: account_request.identity_token)
      )
    end

    it 'should include the admin link to reject the organization' do
      expect(mail.body.encoded)
        .to include(for_rejection_admin_account_requests_url(token: account_request.identity_token))
    end
  end

  describe '#rejection' do
    let(:account_request_id) { account_request.id }
    let(:account_request) {
      FactoryBot.create(:account_request, email: 'me@me.com', rejection_reason: 'because I said so')
    }
    let(:mail) { AccountRequestMailer.rejection(account_request_id: account_request_id) }

    context 'when the account_request_id provided does not match any AccountRequest' do
      let(:account_request_id) { 0 }

      it 'should trigger raise a ActiveRecord::RecordNotFound error' do
        expect { mail.body }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it 'should be sent to the correct email address' do
      expect(mail.to).to eq(['me@me.com'])
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq("Human Essential Account Request Rejected")
    end

    it 'should include the rejection reason' do
      expect(mail.body.encoded).to include('because I said so')
    end
  end
end
