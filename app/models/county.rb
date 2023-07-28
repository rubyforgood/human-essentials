# == Schema Information
#
# Table name: counties
#
#  id         :bigint           not null, primary key
#  category   :enum             default("US_County"), not null
#  name       :string
#  region     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class County < ApplicationRecord
  has_paper_trail
  has_many :served_areas, class_name: "Partners::ServedArea", dependent: :destroy

  SORT_ORDER = %w[US_County Other]

  def self.in_category_name_order
    County.in_order_of(:category, SORT_ORDER).order(:name)
  end
end
