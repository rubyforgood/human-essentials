# == Schema Information
#
# Table name: kits
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#
require 'rails_helper'

RSpec.describe Kit, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
