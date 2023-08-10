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
    end

    it "decreases stored inventory on a negative adjustment" do
      expect do
        adjustment_params = {user_id: @user.id, organization_id: @organization.id, storage_location_id: storage_location.id, line_items_attributes: {"0": {item_id: storage_location.items.first.id, quantity: -5}}}
        subject.new(adjustment_params).call
      end.to change { inventory_item_1.reload.quantity }.by(-5)
    end

    it "increases handles mixed adjustments to same item appropriately (total is positive version)" do
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

    it "handles adjustments to multiple items" do
      quantity_1 = inventory_item_1.quantity
      quantity_2 = inventory_item_2.quantity

      adjustment_params = {user_id: @user.id,
                           organization_id: @organization.id,
                           storage_location_id: storage_location.id,
                           line_items_attributes: {
                             "0": {item_id: item_1.id, quantity: 5},
                             "1": {item_id: item_2.id, quantity: 3},
                             "2": {item_id: item_1.id, quantity: 2}
                           }}
      subject.new(adjustment_params).call
      expect(inventory_item_1.reload.quantity).to eq(quantity_1 + 7)
      expect(inventory_item_2.reload.quantity).to eq(quantity_2 + 3)
    end
  end
end
