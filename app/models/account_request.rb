# == Schema Information
#
# Table name: account_requests
#
#  id                   :bigint           not null, primary key
#  confirmed_at         :datetime
#  email                :string           not null
#  name                 :string           not null
#  organization_name    :string           not null
#  organization_website :string
#  rejection_reason     :string
#  request_details      :text             not null
#  status               :string           default("started"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  ndbn_member_id       :bigint
#
class AccountRequest < ApplicationRecord
  has_paper_trail
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :request_details, presence: true, length: { minimum: 50 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :organization_website, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "should look like 'https://www.example.com'" }, allow_blank: true

  validate :email_not_already_used_by_organization
  validate :email_not_already_used_by_user

  belongs_to :ndbn_member, class_name: 'NDBNMember', optional: true

  has_one :organization, dependent: :nullify

  enum status: %w[started user_confirmed admin_approved rejected].map { |v| [v, v] }.to_h

  scope :requested, -> { where(status: %w[started user_confirmed]) }
  scope :closed, -> { where(status: %w[admin_approved rejected]) }

  def self.get_by_identity_token(identity_token)
    decrypted_token = JWT.decode(identity_token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
    account_request_id = decrypted_token[0]["account_request_id"]

    AccountRequest.find_by(id: account_request_id)
  rescue StandardError
    # The identity_token was determined to not be valid
    # and returns nil to indicate no match found.
    nil
  end

  def identity_token
    raise 'must have an id' unless persisted?

    JWT.encode({ account_request_id: id }, Rails.application.secret_key_base, 'HS256')
  end

  # @return [Boolean]
  def confirmed?
    user_confirmed? || admin_approved?
  end

  # @return [Boolean]
  def processed?
    organization.present?
  end

  def confirm!
    update!(confirmed_at: Time.current, status: 'user_confirmed')
    AccountRequestMailer.approval_request(account_request_id: id).deliver_later
  end

  # @param reason [String]
  def reject!(reason)
    update!(status: 'rejected', rejection_reason: reason)
    AccountRequestMailer.rejection(account_request_id: id).deliver_later
  end

  private

  def email_not_already_used_by_organization
    org = Organization.find_by(email: email)
    if org && org != organization
      errors.add(:email, 'already used by an existing Organization')
    end
  end

  def email_not_already_used_by_user
    user = User.find_by(email: email)
    if user && (!organization || user.organization_id != organization.id)
      errors.add(:email, 'already used by an existing User')
    end
  end
end
