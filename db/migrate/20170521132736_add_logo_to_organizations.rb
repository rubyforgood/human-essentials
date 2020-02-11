# Organizations can now have their own custom logo
class AddLogoToOrganizations < ActiveRecord::Migration[5.0]
  def up
    add_attachment :organizations, :logo
  end

  def down
    remove_attachment :organizations, :logo
  end
end
