RSpec.describe AdjustmentCreateService, type: :service do
  include ActiveJob::TestHelper

  subject { AdjustmentCreateService }
  describe "call" do
    let!(:storage_location) { create(:storage_location, :with_items, item_count: 2) }
    let!(:item_1) { storage_location.items.first }
    let!(:item_2) { storage_location.items.second }
    let!(:inventory_item_1) { InventoryItem.where(storage_location_id: storage_location.id, item_id: storage_location.items.first.id).first }
    let!(:inventory_item_2) { InventoryItem.where(storage_location_id: storage_location.id, item_id: storage_location.items.second.id).first }

    it "increases stored inventory on a positive adjustment" do
      expect do
        adjustment_params = {user_id: @user.id, organization_id: @organization.id, storage_location_id: storage_location.id, line_items_attributes: {"0": {item_id: storage_location.items.first.id, quantity: 5}}}
        subject.new(adjustment_params).call
      end.to change { inventory_item_1.reload.quantity }.by(5)
      expect(AdjustmentEvent.count).to eq(1)
      event = AdjustmentEvent.last
      expect(event.data).to eq(EventTypes::InventoryPayload.new(
        items: [
                 EventTypes::EventLineItem.new(
                   quantity: 5,
                   item_id: item_1.id,
                   from_storage_location: nil,
                   to_storage_location: storage_location.id,
                   item_value_in_cents: 0
                 )
               ]
      )
    )
    end

    it "saves a new adjustment with line items relating to the current (simple case) positive adjustment" do
      expect do
        adjustment_params = {user_id: @user.id, organization_id: @organization.id, storage_location_id: storage_location.id, line_items_attributes: {"0": {item_id: storage_location.items.first.id, quantity: 5}}}
        subject.new(adjustment_params).call
      end.to change { Adjustment.count }.by(1)
      adjustment = Adjustment.last
      expect(adjustment.line_items.count).to eq(1)
      expect(adjustment.line_items[0].quantity).to eq(5)
    end

    it "decreases stored inventory on a negative adjustment" do
      expect do
        adjustment_params = {user_id: @user.id, organization_id: @organization.id, storage_location_id: storage_location.id, line_items_attributes: {"0": {item_id: storage_location.items.first.id, quantity: -5}}}
        subject.new(adjustment_params).call
      end.to change { inventory_item_1.reload.quantity }.by(-5)
      expect(AdjustmentEvent.count).to eq(1)
      event = AdjustmentEvent.last
      expect(event.data).to eq(EventTypes::InventoryPayload.new(
        items: [
                 EventTypes::EventLineItem.new(
                   quantity: -5,
                   item_id: item_1.id,
                   from_storage_location: nil,
                   to_storage_location: storage_location.id,
                   item_value_in_cents: 0
                 )
               ]
      )
    )
    end

    it "saves a new adjustment with line items relating to the current (simple case) negative adjustment" do
      expect do
        adjustment_params = {user_id: @user.id, organization_id: @organization.id, storage_location_id: storage_location.id, line_items_attributes: {"0": {item_id: storage_location.items.first.id, quantity: -5}}}
        subject.new(adjustment_params).call
      end.to change { Adjustment.count }.by(1)

      adjustment = Adjustment.last
      expect(adjustment.line_items.count).to eq(1)
      expect(adjustment.line_items[0].quantity).to eq(-5)
    end

    it "handles mixed adjustments to same item appropriately (total is positive version)" do
      expect do
        adjustment_params = {user_id: @user.id,
                             organization_id: @organization.id,
                             storage_location_id: storage_location.id,
                             line_items_attributes: {
                               "0": {item_id: storage_location.items.first.id, quantity: 4},
                               "1": {item_id: storage_location.items.first.id, quantity: -5},
                               "2": {item_id: storage_location.items.first.id, quantity: 2}
                             }}
        subject.new(adjustment_params).call
      end.to change { inventory_item_1.reload.quantity }.by(1)
      adjustment = Adjustment.last
      expect(adjustment.line_items.count).to eq(1)
      expect(adjustment.line_items[0].quantity).to eq(1)
    end

    it "increases handles mixed adjustments to same appropriately (total is negative version)" do
      expect do
        adjustment_params = {user_id: @user.id,
                             organization_id: @organization.id,
                             storage_location_id: storage_location.id,
                             line_items_attributes: {
                               "0": {item_id: item_1.id, quantity: -4},
                               "1": {item_id: item_1.id, quantity: -5},
                               "2": {item_id: item_1.id, quantity: 2}
                             }}
        subject.new(adjustment_params).call
      end.to change { inventory_item_1.reload.quantity }.by(-7)
      adjustment = Adjustment.last
      expect(adjustment.line_items.count).to eq(1)
      expect(adjustment.line_items[0].quantity).to eq(-7)
    end

    it "does not allow inventory to be adjusted below 0" do
      quantity = -1 * (inventory_item_1.quantity + 1)
      expect do
        adjustment_params = {user_id: @user.id,
                             organization_id: @organization.id,
                             storage_location_id: storage_location.id,
                             line_items_attributes: {
                               "0": {item_id: item_1.id, quantity: quantity}
                             }}
        subject.new(adjustment_params).call
      end.to change { inventory_item_1.reload.quantity }.by(0)
    end

    it "gives an error if we attempt to adjust inventory below 0" do
      quantity = -1 * (inventory_item_1.quantity + 1)
      adjustment_params = {user_id: @user.id,
                           organization_id: @organization.id,
                           storage_location_id: storage_location.id,
                           line_items_attributes: {
                             "0": {item_id: item_1.id, quantity: quantity}
                           }}
      result = subject.new(adjustment_params).call
      expect(result.adjustment.errors.size).to be > 0
      expect(result.adjustment.errors[:inventory][0]).to include("items exceed the available inventory")
    end

    it "handles adjustments to multiple items" do
      quantity_1 = inventory_item_1.quantity
      quantity_2 = inventory_item_2.quantity

      adjustment_params = {user_id: @user.id,
                           organization_id: @organization.id,
                           storage_location_id: storage_location.id,
                           line_items_attributes: {
                             "0": {item_id: item_1.id, quantity: 5},
                             "1": {item_id: item_2.id, quantity: 2},
                             "2": {item_id: item_1.id, quantity: -2}
                           }}
      subject.new(adjustment_params).call
      expect(inventory_item_1.reload.quantity).to eq(quantity_1 + 3)
      expect(inventory_item_2.reload.quantity).to eq(quantity_2 + 2)
      adjustment = Adjustment.last
      expect(adjustment.line_items.count).to eq(2)
      line_item_1 = adjustment.line_items.where(item_id: item_1.id).first
      expect(line_item_1.quantity).to eq(3)
      line_item_2 = adjustment.line_items.where(item_id: item_2.id).first
      expect(line_item_2.quantity).to eq(2)
    end
  end
end
