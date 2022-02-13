# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :integer          default(0)
#  invited_by_type        :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :bigint
#  partner_id             :bigint
#

class User < ApplicationRecord
  include Discard::Model
  belongs_to :organization, optional: proc { |u| u.super_admin? }
  # :invitable is from the devise_invitable gem
  # If you change any of these options, adjust ConsolidatedLoginsController::DeviseMappingShunt accordingly
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable, :password_has_required_content
  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :name, :email, presence: true

  default_scope -> { kept }
  scope :alphabetized, -> { order(discarded_at: :desc, name: :asc) }

  def invitation_status
    return "joined" if current_sign_in_at.present?
    return "accepted" if invitation_accepted_at.present?
    return "invited" if invitation_sent_at.present?
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
    User.where(email: data['email']).first
  end

end
