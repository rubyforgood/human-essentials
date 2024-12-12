# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  discarded_at           :datetime
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :integer          default(0)
#  invited_by_type        :string
#  last_request_at        :datetime
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string
#  organization_admin     :boolean
#  provider               :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  super_admin            :boolean          default(FALSE)
#  uid                    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :integer
#  last_role_id           :bigint
#  organization_id        :integer
#  partner_id             :bigint
#

RSpec.describe User, type: :model do
  context "Validations >" do
    it "user can receive a name" do
      expect(build(:user, name: "foo")).to be_valid
    end

    it "without a name results in display_name 'Name Not Provided'" do
      user = build(:user, name: nil)
      expect(user).to be_valid
      expect(user.name).to be_nil
      expect(user.display_name).to eq("Name Not Provided")
    end

    it "requires an email that is formatted correctly" do
      expect(build(:partner, email: nil)).not_to be_valid
      expect(build(:partner, email: "foo@bar.com")).to be_valid
      expect(build(:partner, email: "boooooooooo")).not_to be_valid
      expect(build(:partner, email: "@boooooooooo")).not_to be_valid
      expect(build(:partner, email: "boooooooooo@")).not_to be_valid
    end

    it "requires a password with a special character and number" do
      expect(build(:user, password: "password", password_confirmation: "password")).not_to be_valid
      expect(build(:user, password: "a;dsfj!55", password_confirmation: "a;dsfj!55")).to be_valid
      expect(build(:user, password: "password5", password_confirmation: "password5")).not_to be_valid
      expect(build(:user, password: "password!5", password_confirmation: "password!5")).to be_valid
    end
  end

  describe "Scopes >" do
    describe "->alphabetized" do
      let!(:z_name_user) { create(:user, name: 'Zachary') }
      let!(:a_name_user) { create(:user, name: 'Amanda') }

      it "retrieves users in the correct order" do
        alphabetized_list = described_class.alphabetized

        expect(alphabetized_list.first).to eq(a_name_user)
        expect(alphabetized_list.last).to eq(z_name_user)
      end
    end
  end

  describe "Scopes >" do
    describe "->alphabetized" do
      let(:discarded_at) { Time.zone.now }

      let!(:z_name_user) { create(:user, name: 'Zachary') }
      let!(:a_name_user) { create(:user, name: 'Amanda') }
      let!(:deactivated_a_name_user) { create(:user, name: 'Alice', discarded_at: discarded_at) }
      let!(:deactivated_z_name_user) { create(:user, name: 'Zeke', discarded_at: discarded_at) }
      let!(:user) { create(:user, name: "DEFAULT USER") }
      let!(:organization_admin) { create(:organization_admin, name: "DEFAULT ORG ADMIN") }
      let!(:super_admin) { create(:organization_admin, name: "DEFAULT SUPERADMIN") }

      it "retrieves users in the correct order" do
        alphabetized_list = described_class.org_users.with_discarded.alphabetized

        expect(alphabetized_list).to eq(
          [
            a_name_user,
            organization_admin,
            super_admin,
            user,
            z_name_user,
            deactivated_a_name_user,
            deactivated_z_name_user
          ]
        )
      end
    end
  end

  context "Methods >" do
    it "#invitation_status" do
      expect(build(:user, invitation_sent_at: Time.zone.parse("2018-10-10 00:00:00")).invitation_status).to eq("invited")
      expect(build(:user, invitation_sent_at: Time.zone.parse("2018-10-10 00:00:00"), invitation_accepted_at: Time.zone.parse("2018-10-11 00:00:00")).invitation_status).to eq("accepted")
      expect(build(:user, invitation_sent_at: Time.zone.parse("2018-10-10 00:00:00"), invitation_accepted_at: Time.zone.parse("2018-10-11 00:00:00"), current_sign_in_at: Time.zone.parse("2018-10-23 00:00:00")).invitation_status).to eq("joined")
    end

    it "#kind" do
      expect(create(:super_admin).kind).to eq("super")
      expect(create(:organization_admin).kind).to eq("admin")
      expect(create(:user).kind).to eq("normal")
    end

    it "#reinvitable?" do
      expect(build(:user, invitation_sent_at: Time.current - 7.days).reinvitable?).to be true
      expect(build(:user, invitation_sent_at: Time.current - 6.days).reinvitable?).to be false
      expect(build(:user, invitation_sent_at: Time.current - 7.days, invitation_accepted_at: Time.current - 7.days).reinvitable?).to be false
    end

    it "discarded?" do
      expect(build(:user, :deactivated).discarded?).to be true
    end
  end

  describe 'omniauth' do
    it 'retrieves the user from an omniauth context' do
      # can't use instance_double since AuthHash uses Hashie for dynamically created methods
      token = double(OmniAuth::AuthHash, info: {'email' => 'me@me.com'})
      expect(described_class.from_omniauth(token)).to eq(nil)
      user = create(:user, email: 'me@me.com')
      expect(described_class.from_omniauth(token)).to eq(user)
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
