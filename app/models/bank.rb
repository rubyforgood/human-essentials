# == Schema Information
#
# Table name: banks
#
#  id                        :bigint           not null, primary key
#  address                   :string
#  email                     :string
#  name                      :string
#  opt_in_email_notification :boolean
#  phone                     :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
require 'uri'
class Bank < ApplicationRecord
  has_many :partner_requests

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :address, presence: true
  validates :opt_in_email_notification, inclusion: { in: [true, false] }
end
