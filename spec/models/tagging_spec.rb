# == Schema Information
#
# Table name: taggings
#
#  id              :bigint           not null, primary key
#  taggable_type   :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#  tag_id          :bigint           not null
#  taggable_id     :bigint           not null
#
require 'rails_helper'

RSpec.describe Tagging, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
