# == Schema Information
#
# Table name: partner_served_areas
#
#  id                 :bigint           not null, primary key
#  client_share       :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  county_id          :bigint           not null
#  partner_profile_id :bigint           not null
#
module Partners
  class ServedArea < ApplicationRecord
    has_paper_trail
    self.table_name = "partner_served_areas"
    belongs_to :partner_profile, class_name: "Partners::Profile"
    belongs_to :county
    validates :client_share, numericality: {only_integer: true}
    validates :client_share, inclusion: {in: 1..100}
  end
end
