# == Schema Information
#
# Table name: child_items
#
#  child_id :bigint           not null
#  item_id  :bigint           not null
#
module Partners
  class ChildItem < ApplicationRecord
    belongs_to :child, class_name: "Partners::Child"
    belongs_to :item
  end
end
