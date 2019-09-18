# == Schema Information
#
# Table name: partners
#
#  id              :integer          not null, primary key
#  name            :string
#  email           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#  send_reminders  :boolean          default(FALSE), not null
#  status          :integer          default("uninvited")
#

RSpec.describe Partner, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:partner, organization_id: nil)).not_to be_valid
    end
    it "requires a unique name" do
      expect(build(:partner, name: nil)).not_to be_valid
      create(:partner, name: "Foo")
      expect(build(:partner, name: "Foo")).not_to be_valid
    end
    it "requires a unique email that is formatted correctly" do
      expect(build(:partner, email: nil)).not_to be_valid
      create(:partner, email: "foo@bar.com")
      expect(build(:partner, email: "foo@bar.com")).not_to be_valid
      expect(build(:partner, email: "boooooooooo")).not_to be_valid
    end
  end

  describe "Filters" do
    describe "by_status" do
      it "yields partners with the provided status" do
        create(:partner, status: :invited)
        create(:partner, status: :approved)
        expect(Partner.by_status('invited').count).to eq(1)
      end
    end
  end
  # context "Callbacks >" do
  #   describe "when DIAPER_PARTNER_URL is present" do
  #     let(:diaper_partner_url) { "http://diaper.partner.io" }
  #     let(:callback_url) { "#{diaper_partner_url}/partners" }
  #
  #     before do
  #       stub_env "DIAPER_PARTNER_URL", diaper_partner_url
  #       stub_env "DIAPER_PARTNER_SECRET_KEY", "secretkey123"
  #       stub_request :post, callback_url
  #     end
  #
  #     it "notifies the Diaper Partner app" do
  #       partner = create :partner
  #       headers = {
  #         "Authorization" => /APIAuth diaperbase:.*/,
  #         "Content-Type" => "application/x-www-form-urlencoded"
  #       }
  #       body = URI.encode_www_form partner.attributes
  #       expect(WebMock).to have_requested(:post, callback_url)
  #         .with(headers: headers, body: body).once
  #     end
  #   end
  # end

  describe "import_csv" do
    let(:organization) { create(:organization) }

    it "imports storage locations from a csv file" do
      before_import = Partner.count
      import_file_path = Rails.root.join("spec", "fixtures", "partners.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      Partner.import_csv(csv, organization.id)
      expect(Partner.count).to eq before_import + 3
    end

    it "imports storage locations from a csv file with BOM encodings" do
      import_file_path = Rails.root.join("spec", "fixtures", "partners_with_bom_encoding.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      expect do
        Partner.import_csv(csv, organization.id)
      end.to change { Partner.count }.by(20)
    end

    it "not send emails after importing a csv file" do
      expect(UpdateDiaperPartnerJob).not_to receive(:perform_async)

      import_file_path = Rails.root.join("spec", "fixtures", "partners.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      Partner.import_csv(csv, organization.id)
    end
  end

  describe '#quantity_year_to_date' do
    let(:partner) { create(:partner) }
    before do
      create(:distribution, :with_items, partner: partner)
      create(:distribution, :with_items, partner: partner)
      create(:distribution, :with_items, partner: partner)
    end

    it "includes all item quantities for the given year" do
      expect(partner.quantity_year_to_date).to eq(300)
    end

    it "does not include quantities from last year" do
      LineItem.last.update(created_at: Time.zone.today.beginning_of_year - 20)
      expect(partner.quantity_year_to_date).to eq(200)
    end
  end
end
