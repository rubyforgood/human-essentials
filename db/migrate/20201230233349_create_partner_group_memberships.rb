class CreatePartnerGroupMemberships < ActiveRecord::Migration[6.0]
  def change
    create_table :partner_group_memberships do |t|
      t.references :partner_group, foreign_key: true
      t.references :partner, foreign_key: true

      t.timestamps
    end
  end
end
