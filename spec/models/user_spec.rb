# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :integer
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_type        :string
#  invited_by_id          :integer
#  invitations_count      :integer          default(0)
#  organization_admin     :boolean
#  name                   :string           default("CHANGEME"), not null
#  super_admin            :boolean          default(FALSE)
#  last_request_at        :datetime
#

RSpec.describe User, type: :model do
  context "Validations >" do
    it "requires a name" do
      expect(build(:user, name: nil)).not_to be_valid
    end
    it "requires an email" do
      expect(build(:user, email: nil)).not_to be_valid
    end
  end

  context "Methods >" do
    it "#most_recent_sign_in" do
      expect(build(:user, current_sign_in_at: Time.zone.parse("2018-10-23 00:00:00"), last_sign_in_at: Time.zone.parse("2018-10-20 00:00:00 UTC")).most_recent_sign_in).to eq("2018-10-23 00:00:00 UTC")
      expect(build(:user, current_sign_in_at: Time.zone.parse("2018-10-24 00:00:00"), last_sign_in_at: nil).most_recent_sign_in).to eq("2018-10-24 00:00:00 UTC")
      expect(build(:user).most_recent_sign_in).to eq("")
    end

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

    it "#reinvatable?" do
      expect(build(:user, invitation_sent_at: Time.current - 7.days).reinvitable?).to be true
      expect(build(:user, invitation_sent_at: Time.current - 6.days).reinvitable?).to be false
      expect(build(:user, invitation_sent_at: Time.current - 7.days, invitation_accepted_at: Time.current - 7.days).reinvitable?).to be false
    end
  end
end
