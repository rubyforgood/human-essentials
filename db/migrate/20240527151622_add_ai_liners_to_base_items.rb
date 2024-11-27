class AddAiLinersToBaseItems < ActiveRecord::Migration[7.0]
  def up
    BaseItem.find_or_create_by!(name: "Liners (Incontinence)", category: "Incontinence Pads - Adult", partner_key: "ai_liners")
  end
  def down
    BaseItem.where(partner_key:"ai_liners").destroy_all
  end
end
