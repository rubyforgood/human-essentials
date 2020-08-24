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

    it 'should be from info@diaper.app' do
      expect(mail.from).to eq(['info@diaper.app'])
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq('[Action Required] Diaperbase Account Request')
    end

    it 'should include the staging/demo account information' do
      expect(mail.body.encoded).to match(%r{<a href='https://diaperbase.org/'>DiaperBase</a>})
      expect(mail.body.encoded).to match('Username: org_admin1@example.com')
      expect(mail.body.encoded).to match('Password: password')

      expect(mail.body.encoded).to match(%r{<a href='https://partnerbase.org/'>PartnerBase</a>})
      expect(mail.body.encoded).to match('Username: verified@example.com')
      expect(mail.body.encoded).to match('Password: password')
    end

    it 'should include the instruction video link' do
      expect(mail.body.encoded).to include('https://www.youtube.com/watch?v=fwo3WKMGM_4&feature=youtu.be')
    end

    it 'should include the button to confirm the request' do
      expect(mail.body.encoded).to include(
        confirmation_account_requests_url(token: account_request.identity_token)
      )
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

    it 'should be sent to the info@diaper.app email address' do
      expect(mail.to).to eq(['info@diaper.app'])
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
  end
end
