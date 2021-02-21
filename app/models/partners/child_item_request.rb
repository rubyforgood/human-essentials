module Partners
  class ChildItemRequest < Base
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
