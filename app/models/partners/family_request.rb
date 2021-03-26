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
        Item.new(params.slice(:item_id, :person_count, :children))
      end
    end

    def as_payload
      {
        organization_id: partner&.diaper_bank_id,
        partner_id: partner&.diaper_partner_id,
        requested_items: items.map(&:as_payload)
      }
    end

    class Item
      include ActiveModel::Model

      attr_accessor :item_id, :person_count, :children

      def as_payload
        { item_id: item_id&.to_i, person_count: person_count&.to_i }
      end
    end
  end
end
