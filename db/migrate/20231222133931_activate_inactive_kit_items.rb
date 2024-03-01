class ActivateInactiveKitItems < ActiveRecord::Migration[7.0]
  def up
    Kit.all.each do |kit|
      kit.line_items.each do |line_item|
        unless line_item.item.active?
          line_item.item.update!(active: true, visible_to_partners: false)
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
