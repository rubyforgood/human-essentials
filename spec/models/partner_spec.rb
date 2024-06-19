# == Schema Information
#
# Table name: partners
#
#  id                          :integer          not null, primary key
#  email                       :string
#  name                        :string
#  notes                       :text
#  quota                       :integer
#  send_reminders              :boolean          default(FALSE), not null
#  status                      :integer          default("uninvited")
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  default_storage_location_id :bigint
#  organization_id             :integer
#  partner_group_id            :bigint
#

RSpec.describe Partner, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:partner_group).optional }
    it { should have_many(:item_categories).through(:partner_group) }
    it { should have_many(:requestable_items).through(:item_categories).source(:items) }
    it { should have_many(:requests) }
    it { should have_many(:distributions) }
    it { should have_many(:requests) }
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:families).dependent(:destroy) }
    it { should have_many(:children).through(:families) }

    describe 'primary_user' do
      subject { partner.primary_user }
      let(:partner) { create(:partner) }
      before do
        second_user = partner.primary_user.clone
        second_user.email = Faker::Internet.email
        second_user.save!
      end

      it 'should return the first user ever created for a partner' do
        expect(subject).to eq(partner.primary_user)
      end
    end
  end

  context "Validations >" do
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
      expect(build(:partner, name: "Foo", email: "FOO@example.com", organization: build(:organization))).to_not be_valid
    end

    it "requires a unique email that is formatted correctly" do
      expect(build(:partner, email: nil)).not_to be_valid
      create(:partner, email: "foo@bar.com")
      expect(build(:partner, email: "foo@bar.com")).not_to be_valid
      expect(build(:partner, email: "boooooooooo")).not_to be_valid
    end

    it { should validate_numericality_of(:quota).allow_nil }
  end

  context "callbacks" do
    it "properly downcases email" do
      partner = create(:partner, name: "Foo", email: "Foo@example.com")
      expect(partner.email).to eq("foo@example.com")
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

  describe '#deletable?' do
    context 'when status is not uninvited' do
      it 'should return false' do
        expect(build(:partner, status: :invited)).not_to be_deletable
        expect(build(:partner, status: :awaiting_review)).not_to be_deletable
        expect(build(:partner, status: :approved)).not_to be_deletable
        expect(build(:partner, status: :error)).not_to be_deletable
        expect(build(:partner, status: :recertification_required)).not_to be_deletable
        expect(build(:partner, status: :deactivated)).not_to be_deletable
      end
    end

    context 'when status is uninvited' do
      let(:partner) { create(:partner, :uninvited, without_profile: true) }

      context 'when it has no other associations' do
        it 'should return true' do
          expect(partner).to be_deletable
        end
      end

      context 'when it has a request' do
        it 'should return false' do
          create(:request, partner: partner)
          expect(partner.reload).not_to be_deletable
        end
      end
      context 'when it has a distribution' do
        it 'should return false' do
          create(:distribution, partner: partner)
          expect(partner.reload).not_to be_deletable
        end
      end
      context 'when it has a profile but no users' do
        it 'should return true' do
          create(:partner_profile, partner_id: partner.id, name: partner.name)
          expect(partner.reload).to be_deletable
        end
      end
      context 'when it has a profile and users' do
        it 'should return false' do
          create(:partner_profile, partner_id: partner.id)
          create(:partners_user, email: partner.email, name: partner.name, partner: partner)
          expect(partner.reload).not_to be_deletable
        end
      end
    end
  end

  describe '#approvable?' do
    context 'when status is invited' do
      it 'should return true' do
        expect(build(:partner, status: :invited)).to be_approvable
      end
    end

    context 'when status is awaiting_review' do
      it 'should return true' do
        expect(build(:partner, status: :awaiting_review)).to be_approvable
      end
    end

    context 'when status is not invited or awaiting_review' do
      it 'should return false', :aggregate_failures do
        expect(build(:partner, status: :uninvited)).not_to be_approvable
        expect(build(:partner, status: :approved)).not_to be_approvable
        expect(build(:partner, status: :error)).not_to be_approvable
        expect(build(:partner, status: :recertification_required)).not_to be_approvable
        expect(build(:partner, status: :deactivated)).not_to be_approvable
      end
    end
  end

  describe 'changing emails' do
    let(:partner) { create(:partner, status: :invited) }
    before do
      allow(UserInviteService).to receive(:invite)
    end

    [:invited, :awaiting_review, :recertification_required, :approved].each do |test_status|
      it "should call the UserInviteService.invite when the partner has status #{test_status} and the email is changed" do
        partner.status = test_status
        partner.email = "randomtest@email.com"
        partner.save!
        expect(UserInviteService).to have_received(:invite).with(
          email: "randomtest@email.com",
          roles: [Role::PARTNER],
          resource: partner
        )
      end
    end

    it "should not call the UserInviteService.invite when the partner is changing email to previously used email" do
      previous_email = partner.email
      partner.email = "randomtest@email.com"
      partner.save!
      partner.email = previous_email
      partner.save!
      expect(UserInviteService).not_to have_received(:invite).with(
        email: previous_email,
        roles: [Role::PARTNER],
        resource: partner
      )
      expect(UserInviteService).to have_received(:invite).with(
        email: "randomtest@email.com",
        roles: [Role::PARTNER],
        resource: partner
      )
    end

    [:uninvited, :deactivated].each do |test_status|
      it "should not call the UserInviteService.invite when the partner has status #{test_status} and the email is changed" do
        partner.status = test_status
        partner.email = "randomtest@email.com"
        partner.save!
        expect(UserInviteService).not_to have_received(:invite).with(
          email: "randomtest@email.com",
          roles: [Role::PARTNER],
          resource: partner
        )
      end
    end
  end
  describe '#profile' do
    subject { partner.profile }
    let(:partner) { create(:partner) }

    it 'should return the associated Partners::Profile record' do
      expect(subject).to eq(Partners::Profile.find_by(partner_id: partner.id))
    end
  end

  describe "import_csv" do
    let(:organization) { create(:organization) }

    it "imports partners from a csv file and prevents multiple imports" do
      before_import = Partner.count
      import_file_path = Rails.root.join("spec", "fixtures", "files", "partners.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      Partner.import_csv(csv, organization.id)
      expect(Partner.count).to eq before_import + 3
      import_file_path2 = Rails.root.join("spec", "fixtures", "files", "partners_with_duplicates.csv")
      data2 = File.read(import_file_path2, encoding: "BOM|UTF-8")
      csv2 = CSV.parse(data2, headers: true)
      Partner.import_csv(csv2, organization.id)
      expect(Partner.count).to eq before_import + 4
    end

    it "imports partners from a csv file with BOM encodings" do
      import_file_path = Rails.root.join("spec", "fixtures", "files", "partners_with_bom_encoding.csv")
      data = File.read(import_file_path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true)
      expect do
        Partner.import_csv(csv, organization.id)
      end.to change { Partner.count }.by(20)
    end
  end

  describe "#csv_export_attributes" do
    let!(:partner) { create(:partner) }

    let(:contact_name) { "Jon Ralfeo" }
    let(:contact_email) { "jon@entertainment720.com" }
    let(:contact_phone) { "1231231234" }
    let(:agency_address1) { "4744 McDermott Mountain" }
    let(:agency_address2) { "333 Never land street" }
    let(:agency_city) { "Lake Shoshana" }
    let(:agency_state) { "ND" }
    let(:agency_zipcode) { "09980-7010" }
    let(:agency_website) { "bosco.example" }
    let(:agency_type) { Partner::AGENCY_TYPES["OTHER"] }
    let(:other_agency_type) { "Another Agency Name" }
    let(:notes) { "Some notes" }

    before do
      partner.profile.update({
                               primary_contact_name: contact_name,
                               primary_contact_email: contact_email,
                               primary_contact_phone: contact_phone,
                               address1: agency_address1,
                               address2: agency_address2,
                               city: agency_city,
                               state: agency_state,
                               zip_code: agency_zipcode,
                               website: agency_website,
                               agency_type: agency_type,
                               other_agency_type: other_agency_type
                             })
      partner.update(notes: notes)
    end

    it "should has the info in the columns order" do
      expect(partner.csv_export_attributes).to eq([
        partner.name,
        partner.email,
        "#{agency_address1}, #{agency_address2}",
        agency_city,
        agency_state,
        agency_zipcode,
        agency_website,
        "#{Partner::AGENCY_TYPES["OTHER"]}: #{other_agency_type}",
        contact_name,
        contact_phone,
        contact_email,
        notes
      ])
    end
  end

  describe '#quantity_year_to_date' do
    let(:partner) { create(:partner) }
    before do
      create(:distribution, :with_items, partner: partner)
      create(:distribution, :with_items, partner: partner)
      create(:distribution, :with_items, partner: partner)
    end

    it "includes all item quantities from distributions issued during the current year" do
      expect(partner.quantity_year_to_date).to eq(300)
    end

    it "does not include quantities from distributions issued during the previous year" do
      partner.distributions.last.update(issued_at: Time.zone.today.beginning_of_year - 20)
      expect(partner.quantity_year_to_date).to eq(200)
    end
  end

  describe "ActiveStorage validation" do
    it "validates that attachments are pdf or docs" do
      partner = build(:partner, documents: [Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.jpg"), "image/jpeg")])

      expect(partner).to_not be_valid

      partner = build(:partner, documents: [Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/dbase.pdf"), "application/pdf")])

      expect(partner).to be_valid
    end
  end

  describe "#impact_metrics" do
    subject { partner.impact_metrics }
    let(:partner) { create(:partner) }

    context "when partner has related information" do
      let!(:family1) { create(:partners_family, guardian_zip_code: "45612-123", partner: partner) }
      let!(:family2) { create(:partners_family, guardian_zip_code: "45612-126", partner: partner) }
      let!(:family3) { create(:partners_family, guardian_zip_code: "45612-123", partner: partner) }

      let!(:child1) { create_list(:partners_child, 2, family: family1) }
      let!(:child2) { create_list(:partners_child, 2, family: family3) }

      it { is_expected.to eq({families_served: 3, children_served: 4, family_zipcodes: 2, family_zipcodes_list: %w[45612-123 45612-126]}) }
    end

    context "when partner don't have any related information" do
      it { is_expected.to eq({families_served: 0, children_served: 0, family_zipcodes: 0, family_zipcodes_list: []}) }
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
