module Partners
  class FamilyRequest
    include ActiveModel::Model

    attr_accessor :comments, :partner
    attr_reader :items

    def initialize(params, partner: nil, initial_items: nil)
      @items = [Item.new] * initial_items if initial_items
      @partner = partner
      super(params)
    end

    def items_attributes=(attributes)
      @items = attributes.map do |_, params|
        Item.new(params.slice(:item_id, :person_count))
      end
    end

    def self.new_with_attrs(request_attrs)
      items_attributes = request_attrs.map.with_index { |x, i| [i, x] }.to_h
      request = new({}, initial_items: 1)
      request.items_attributes = items_attributes
      request
    end

    class Item
      include ActiveModel::Model

      attr_accessor :item_id, :person_count, :children
    end
  end
end
