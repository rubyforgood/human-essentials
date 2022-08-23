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
#  name                   :string           default("Name Not Provided"), not null
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
#  organization_id        :integer
#  partner_id             :bigint
#

class User < ApplicationRecord
  include Discard::Model
  belongs_to :organization, optional: true
  belongs_to :partner, class_name: "Partners::Partner", optional: true

  # :invitable is from the devise_invitable gem
  # If you change any of these options, adjust ConsolidatedLoginsController::DeviseMappingShunt accordingly
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable
  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :name, :email, presence: true
  validate :password_complexity

  default_scope -> { kept }
  scope :alphabetized, -> { order(discarded_at: :desc, name: :asc) }
  scope :partner_users, -> { where.not(partner_id: nil) }
  scope :org_users, -> { where.not(organization_id: nil) }

  has_many :requests, class_name: "Partners::Request", foreign_key: :partner_id, dependent: :destroy, inverse_of: :partner_user
  has_many :submitted_partner_requests, class_name: "Partners::Request", foreign_key: :partner_user_id, dependent: :destroy, inverse_of: :partner_user
  has_many :submitted_requests, class_name: "Request", foreign_key: :partner_user_id, dependent: :destroy, inverse_of: :partner_user

  def password_complexity
    return if password.blank? || password =~ /(?=.*?[#?!@$%^&*-])/

    errors.add :password, "Complexity requirement not met. Please use at least 1 special character"
  end

  def invitation_status
    return "joined" if current_sign_in_at.present?
    return "accepted" if invitation_accepted_at.present?
    "invited" if invitation_sent_at.present?
  end

  def kind
    return "super" if super_admin?
    return "admin" if organization_admin?

    "normal"
  end

  def flipper_id
    "User:#{id}"
  end

  def reinvitable?
    return true if invitation_status == "invited" && invitation_sent_at <= 7.days.ago

    false
  end

  def self.from_omniauth(access_token)
    data = access_token.info
    User.find_by(email: data["email"])
  end
end
