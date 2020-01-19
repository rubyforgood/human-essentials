# == Schema Information
#
# Table name: users
#
#  id                     :bigint          not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :bigint
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :bigint          default(0)
#  invited_by_type        :string
#  last_request_at        :datetime
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  name                   :string           default("CHANGEME"), not null
#  organization_admin     :boolean
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :bigint          default(0), not null
#  super_admin            :boolean          default(FALSE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :bigint
#  organization_id        :bigint
#

class User < ApplicationRecord
  belongs_to :organization, optional: proc { |u| u.super_admin? }
  has_many :feedback_messages, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # :invitable is from the devise_invitable gem
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable

  validates :name, :email, presence: true

  scope :alphabetized, -> { order(:name) }

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
end
