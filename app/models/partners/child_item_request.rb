# == Schema Information
#
# Table name: child_item_requests
#
#  id                          :bigint           not null, primary key
#  picked_up                   :boolean          default(FALSE)
#  picked_up_item_diaperid     :integer
#  quantity_picked_up          :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  authorized_family_member_id :integer
#  child_id                    :bigint
#  item_request_id             :bigint
#
module Partners
  class ChildItemRequest < Base
    has_paper_trail
    belongs_to :item_request
    belongs_to :child
    belongs_to :authorized_family_member, optional: true

    def quantity
      item_request.quantity.to_i / item_request.children.size
    end

    def ordered_item_diaperid
      item_request.item_id
    end
  end
end
