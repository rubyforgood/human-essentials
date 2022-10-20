# == Schema Information
#
# Table name: partner_counties
#
#  id           :bigint           not null, primary key
#  client_share :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  county_id    :bigint           not null
#  partner_id   :bigint           not null
#
require 'rails_helper'

RSpec.describe PartnerCounty, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
