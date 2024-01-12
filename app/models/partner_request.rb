# == Schema Information
#
# Table name: partner_requests
#
#  id              :bigint           not null, primary key
#  comments        :text
#  for_families    :boolean
#  sent            :boolean          default(FALSE), not null
#  status          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  bank_id         :bigint           not null
#  organization_id :bigint
#  partner_id      :bigint
#  partner_user_id :integer
#
require 'uri'
class PartnerRequest < ApplicationRecord
  belongs_to :bank
  validates :status, presence: true
end
