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
#  request_details      :text             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class AccountRequest < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :request_details, presence: true, length: { minimum: 50 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  validate :email_not_already_used_by_organization
  validate :email_not_already_used_by_user

  has_one :organization, dependent: :nullify

  def self.get_by_identity_token(identity_token)
    decrypted_token = JWT.decode(identity_token, Rails.application.secrets[:secret_key_base], true, { algorithm: 'HS256' })
    account_request_id = decrypted_token[0]["account_request_id"]

    AccountRequest.find_by(id: account_request_id)
  rescue StandardError
    # The identity_token was determined to not be valid
    # and returns nil to indicate no match found.
    nil
  end

  def identity_token
    raise 'must have an id' unless persisted?

    JWT.encode({ account_request_id: id }, Rails.application.secrets[:secret_key_base], 'HS256')
  end

  def confirmed?
    confirmed_at.present?
  end

  def processed?
    organization.present?
  end

  private

  def email_not_already_used_by_organization
    if Organization.find_by(email: email)
      errors.add(:email, 'already used by an existing Organization')
    end
  end

  def email_not_already_used_by_user
    if User.find_by(email: email)
      errors.add(:email, 'already used by an existing User')
    end
  end
end
