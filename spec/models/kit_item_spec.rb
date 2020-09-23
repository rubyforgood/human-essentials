# == Schema Information
#
# Table name: kit_items
#
#  id         :bigint           not null, primary key
#  quantity   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  item_id    :integer
#  kit_id     :integer
#
require 'rails_helper'

RSpec.describe KitItem, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
