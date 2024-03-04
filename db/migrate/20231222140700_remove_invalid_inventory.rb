class RemoveInvalidInventory < ActiveRecord::Migration[7.0]
  def up
    return if Rails.env.development?

    admin_role = Role.find_by(name: 'super_admin')
    user = UsersRole.where(role_id: admin_role.id).first.user

    StorageLocation.all.each do |loc|
      adjustment = Adjustment.new(
        organization_id: loc.organization_id,
        storage_location_id: loc.id,
        user_id: user.id,
        comment: "Removing inactive items from inventory")
      loc.inventory_items.joins(:item).where(items: { active: false }).where('quantity > 0').each do |ii|
        adjustment.line_items.push(LineItem.new(item_id: ii.item_id, quantity: -ii.quantity))
      end
      if adjustment.line_items.any?
        AdjustmentCreateService.new(adjustment).call
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
