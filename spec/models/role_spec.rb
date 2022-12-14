# == Schema Information
#
# Table name: roles
#
#  id              :bigint           not null, primary key
#  name            :string
#  resource_type   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  old_resource_id :bigint
#  resource_id     :bigint
#
require "rails_helper"

RSpec.describe Role, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
