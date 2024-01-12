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
require 'rails_helper'

RSpec.describe PartnerRequest, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
