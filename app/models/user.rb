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

  def most_recent_sign_in
    [current_sign_in_at.to_s, last_sign_in_at.to_s].max
  end

  def invitation_status
    return "joined" if most_recent_sign_in.present?
    return "accepted" if invitation_accepted_at.present?
    return "invited" if invitation_sent_at.present?
  end

  def kind
    return "super" if super_admin?
    return "admin" if organization_admin?

    "normal"
  end

  def reinvitable?
    return true if invitation_status == "invited" && invitation_sent_at <= 7.days.ago

    false
  end
end
