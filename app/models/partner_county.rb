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
class PartnerCounty < ApplicationRecord
  belongs_to :partner
  belongs_to :county
  validates :client_share, numericality: {only_integer: true}
  validates :client_share, inclusion: {in: 1..100}
end
