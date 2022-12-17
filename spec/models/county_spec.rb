# == Schema Information
#
# Table name: counties
#
#  id         :bigint           not null, primary key
#  name       :string
#  region     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe County, type: :model do
  it { should have_many(:served_areas) }
end
