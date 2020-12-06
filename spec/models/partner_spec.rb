# == Schema Information
#
# Table name: partners
#
#  id              :integer          not null, primary key
#  email           :string
#  name            :string
#  notes           :text
#  quota           :integer
#  send_reminders  :boolean          default(FALSE), not null
#  status          :integer          default("uninvited")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe Partner, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:partner, organization_id: nil)).not_to be_valid
    end

    it "requires a unique name within an organization" do
      expect(build(:partner, name: nil)).not_to be_valid
      create(:partner, name: "Foo")
      expect(build(:partner, name: "Foo")).not_to be_valid
    end

    it "does not require a unique name between organizations" do
      create(:partner, name: "Foo")
      expect(build(:partner, name: "Foo", organization: build(:organization))).to be_valid
    end

    it "still requires a unique email between organizations" do
      create(:partner, name: "Foo", email: "foo@example.com")
      expect(build(:partner, name: "Foo", email: "foo@example.com", organization: build(:organization))).to_not be_valid
    end

    it "requires a unique email that is formatted correctly" do
      expect(build(:partner, email: nil)).not_to be_valid
      create(:partner, email: "foo@bar.com")
      expect(build(:partner, email: "foo@bar.com")).not_to be_valid
      expect(build(:partner, email: "boooooooooo")).not_to be_valid
    end

    it "validates the quota is a number but it is not required" do
      is_expected.to validate_numericality_of(:quota)
      expect(build(:partner, email: "foo@bar.com", quota: "")).to be_valid
    end
  end

  describe "Filters" do
    describe "by_status" do
      it "yields partners with the provided status" do
        create(:partner, status: :invited)
        create(:partner, status: :approved)
        expect(Partner.by_status('invited').count).to eq(1)
      end
      it "yields deactivated partner when deactivated status provided" do
        create(:partner, status: :deactivated)
        create(:partner, status: :approved)
        expect(Partner.by_status('deactivated').count).to eq(1)
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
  #
  #   end
  # end

  describe '#deactivated?' do
    subject { partner.deactivated? }
    let(:partner) { build(:partner) }

    context "when the status is 'deactivated'" do
      before do
        partner.status = 'deactivated'
      end

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end

    context "when the status is not 'deactivated'" do
      before do
        partner.status = 'invited'
      end

      it 'should return false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe "import_csv" do
    let(:organization) { create(:organization) }

    it "imports partners from a csv file and prevents multiple imports" do
      before_import = Partner.count
      import_file_path = Rails.root.join("spec", "fixtures", "partners.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      Partner.import_csv(csv, organization.id)
      expect(Partner.count).to eq before_import + 3
      import_file_path2 = Rails.root.join("spec", "fixtures", "partners_with_duplicates.csv")
      data2 = File.read(import_file_path2, encoding: "BOM|UTF-8")
      csv2 = CSV.parse(data2, headers: true)
      Partner.import_csv(csv2, organization.id)
      expect(Partner.count).to eq before_import + 4
    end

    it "imports partners from a csv file with BOM encodings" do
      import_file_path = Rails.root.join("spec", "fixtures", "partners_with_bom_encoding.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      expect do
        Partner.import_csv(csv, organization.id)
      end.to change { Partner.count }.by(20)
    end

    it "not send emails after importing a csv file" do
      expect(UpdateDiaperPartnerJob).not_to receive(:perform_now)

      import_file_path = Rails.root.join("spec", "fixtures", "partners.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      Partner.import_csv(csv, organization.id)
    end
  end

  describe "#csv_export_attributes" do
    let!(:partner) { create(:partner) }
    let(:partnerbase_partner) do
      {
        agency: {
          contact_person: {
            name: "Jon Ralfeo",
            phone: "1231231234",
            email: "jon@entertainment720.com"
          }
        }
      }.to_json
    end

    before do
      allow(DiaperPartnerClient).to receive(:get).with({ id: partner.id }) { partnerbase_partner }
    end

    it "includes contact person information from parnerbase" do
      expect(partner.csv_export_attributes).to include("Jon Ralfeo")
      expect(partner.csv_export_attributes).to include("1231231234")
      expect(partner.csv_export_attributes).to include("jon@entertainment720.com")
    end
  end

  describe '#contact_person' do
    let(:partner) { create(:partner) }

    it "checks for agency in response before fetching contact info" do
      allow(partner).to receive(:partnerbase_partner) { instance_double('partnerbase_partner', agency: nil) }
      expect(partner.contact_person).to eq({})
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

  describe "ActiveStorage validation" do
    it "validates that attachments are pdf or docs" do
      partner = build(:partner, documents: [Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/logo.jpg"), "image/jpeg")])

      expect(partner).to_not be_valid

      partner = build(:partner, documents: [Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/dbase.pdf"), "application/pdf")])

      expect(partner).to be_valid
    end
  end
end
