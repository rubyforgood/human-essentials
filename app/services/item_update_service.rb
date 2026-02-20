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

    item.kit.update_value_in_cents
  end
end
