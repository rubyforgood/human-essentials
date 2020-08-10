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
      expect(mail.body.encoded).to match(/<a href='https:\/\/diaperbase.org\/'>DiaperBase<\/a>/)
      expect(mail.body.encoded).to match('Username: org_admin1@example.com')
      expect(mail.body.encoded).to match('Password: password')

      expect(mail.body.encoded).to match(/<a href='https:\/\/partnerbase.org\/'>PartnerBase<\/a>/)
      expect(mail.body.encoded).to match('Username: verified@example.com')
      expect(mail.body.encoded).to match('Password: password')
    end

    it 'should include the instruction video link' do
      expect(mail.body.encoded).to include('https://www.youtube.com/watch?v=fwo3WKMGM_4&feature=youtu.be')
    end
  end

end
