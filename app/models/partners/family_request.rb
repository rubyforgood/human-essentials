module Partners
  class FamilyRequest
    include ActiveModel::Model

    attr_accessor :comments, :partner
    attr_reader :items

    def initialize(params, partner: nil, initial_items: nil)
      @items = [Item.new] * initial_items if initial_items
      @partner = partner
      super params
    end

    def items_attributes=(attributes)
      @items = attributes.map do |_, params|
        Item.new(params.slice(:item_id, :person_count))
      end
    end

    class Item
      include ActiveModel::Model

      attr_accessor :item_id, :person_count, :children
    end
  end
end
