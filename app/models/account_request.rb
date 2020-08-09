# == Schema Information
#
# Table name: account_requests
#
#  id                   :bigint           not null, primary key
#  email                :string           not null
#  organization_name    :string           not null
#  organization_website :string
#  request_details      :text             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class AccountRequest < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :request_details, presence: true, length: { minimum: 50 }
  validates_format_of :email, with: URI::MailTo::EMAIL_REGEXP

  validate :email_not_already_used_by_organization
  validate :email_not_already_used_by_user

  private

  def email_not_already_used_by_organization
    if Organization.find_by(email: self.email)
      errors.add(:email, 'already used by an existing Organization')
    end
  end

  def email_not_already_used_by_user
    if User.find_by(email: self.email)
      errors.add(:email, 'already used by an existing User')
    end
  end

end
