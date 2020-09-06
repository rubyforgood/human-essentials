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
#  name                   :string           default("CHANGEME"), not null
#  organization_admin     :boolean
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  super_admin            :boolean          default(FALSE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :integer
#  organization_id        :integer
#

RSpec.describe User, type: :model do
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  context "Associations" do
    it {
      expect(described_class.reflect_on_association(:organization).macro)
        .to eq(:belongs_to)
    }
    it {
      expect(described_class.reflect_on_association(:feedback_messages).macro)
        .to eq(:has_many)
    }
  end

  context "Validations >" do
    it "requires a name" do
      expect(build(:user, name: nil)).not_to be_valid
      expect(build(:user, name: "foo")).to be_valid
    end
    it "requires an email" do
      expect(build(:user, email: nil)).not_to be_valid
      expect(build(:user, email: "foo@bar.com")).to be_valid
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

      it "retrieves users in the correct order" do
        alphabetized_list = described_class.with_discarded.alphabetized

        expect(alphabetized_list).to eq(
          [
            a_name_user,
            @organization_admin,
            @super_admin,
            @super_admin_no_org,
            @user,
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
      expect(build(:super_admin).kind).to eq("super")
      expect(build(:organization_admin).kind).to eq("admin")
      expect(build(:user).kind).to eq("normal")
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
end
