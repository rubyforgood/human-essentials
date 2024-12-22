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
class Tagging < ApplicationRecord
  belongs_to :organization
  belongs_to :tag
  belongs_to :taggable, polymorphic: true
end
