class Add5T6TPullupsToBaseItems < ActiveRecord::Migration[7.0]
  def up
    BaseItem.find_or_create_by!(name: "Kids Pull-Ups (5T-6T)", category: "Diapers - Childrens", partner_key: "pullup_56t")
  end
  def down
    BaseItem.where(partner_key:"pullup_56t").destroy_all
  end
end
