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
require "rails_helper"

RSpec.describe County, type: :model, skip_seed: true do
  it { should have_many(:served_areas) }

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
