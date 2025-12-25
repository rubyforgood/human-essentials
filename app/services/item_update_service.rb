# frozen_string_literal: true

class ItemUpdateService
  attr_reader :item, :params, :request_unit_ids
  def initialize(item:, params:, request_unit_ids: [])
    @item = item
    @request_unit_ids = request_unit_ids
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      item.update!(params)
      update_kit_value
      if Flipper.enabled?(:enable_packs)
        item.sync_request_units!(request_unit_ids)
      end
    end
    Result.new(value: item)
  rescue => e
    Result.new(error: e)
  end

  private

  def update_kit_value
    return unless item.kit

    kit_value_in_cents = item.kit.items.reduce(0) do |sum, i|
      sum + i.value_in_cents.to_i * item.kit.line_items.find_by(item_id: i.id).quantity.to_i
    end
    item.kit.update!(value_in_cents: kit_value_in_cents)
  end
end
