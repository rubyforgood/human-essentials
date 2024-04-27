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

class User < ApplicationRecord
  before_validation :normalize_blank_name_to_nil
  has_paper_trail
  rolify
  include Discard::Model

  has_one :organization_role_join, class_name: "UsersRole", dependent: :destroy
  has_one :organization_role, through: :organization_role_join, class_name: "Role", source: :role

  belongs_to :last_role_join, class_name: "UsersRole", optional: true, inverse_of: :user, foreign_key: :last_role_id
  has_one :last_role, through: :last_role_join, class_name: "Role", source: :role

  accepts_nested_attributes_for :organization_role_join
  has_one :organization, through: :organization_role, source: :resource, source_type: "Organization"
  has_many :organizations, through: :roles, source: :resource, source_type: "Organization"

  has_one :partner_role_join, class_name: "UsersRole", dependent: :destroy
  has_one :partner_role, through: :partner_role_join, class_name: "Role", source: :role
  has_one :partner, through: :partner_role, source: :resource, source_type: "Partner"
  has_many :partners, through: :roles, source: :resource, source_type: "Partner"

  attr_accessor :organization_admin # for creation / update time

  # :invitable is from the devise_invitable gem
  # If you change any of these options, adjust ConsolidatedLoginsController::DeviseMappingShunt accordingly
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable
  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :email, presence: true, uniqueness: {case_sensitive: false},
  format: {with: URI::MailTo::EMAIL_REGEXP, on: :create}

  validate :password_complexity

  default_scope -> { kept }
  scope :alphabetized, -> { order(discarded_at: :desc, name: :asc) }
  scope :partner_users, -> { with_role(Role::PARTNER, :any) }
  scope :org_users, -> { with_role(Role::ORG_USER, :any) }
  scope :search_name, ->(query) { where("name ilike ?", "%#{query}%") }
  scope :search_email, ->(query) { where("email LIKE ?", "%#{query}%") }

  filterrific(
    available_filters: [
      :search_name,
      :search_email
    ]
  )

  has_many :requests, class_name: "::Request", foreign_key: :partner_id, dependent: :destroy, inverse_of: :partner_user
  has_many :submitted_requests, class_name: "Request", foreign_key: :partner_user_id, dependent: :destroy, inverse_of: :partner_user

  def normalize_blank_name_to_nil
    self.name = nil if name.blank?
  end

  def display_name
    name.presence || "Name Not Provided"
  end

  def formatted_email
    email.present? ? "#{name} <#{email}>" : ""
  end

  def password_complexity
    return if password.blank? || password =~ /(?=.*?[#?!@$%^&*\-;,.()=+|:])/

    errors.add :password, "Complexity requirement not met. Please use at least 1 special character"
  end

  def invitation_status
    return "joined" if current_sign_in_at.present?
    return "accepted" if invitation_accepted_at.present?
    "invited" if invitation_sent_at.present?
  end

  def kind
    return "super" if has_role?(Role::SUPER_ADMIN)
    return "admin" if has_role?(Role::ORG_ADMIN, organization)
    return "normal" if has_role?(Role::ORG_USER, organization)
    return "partner" if has_role?(Role::PARTNER, partner)

    "normal"
  end

  def switchable_roles
    all_roles = roles.to_a.group_by(&:resource_id)
    all_roles.values.each do |role_list|
      if role_list.any? { |r| r.name == Role::ORG_ADMIN.to_s }
        role_list.delete_if { |r| r.name == Role::ORG_USER.to_s }
      end
    end
    all_roles.values.flatten
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
