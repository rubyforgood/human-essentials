# == Schema Information
#
# Table name: item_categories
#
#  id              :bigint           not null, primary key
#  description     :text
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
require 'rails_helper'

RSpec.describe ItemCategory, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
