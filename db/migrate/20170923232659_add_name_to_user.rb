# Amazingly, users did not yet have a name field
class AddNameToUser < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :name, :string, null: false, default: "CHANGEME"
    # puts "Updating existing users:"
    # User.all.each do |u|
    #   new_name = u.email.split("@").first
    #   u.update_attributes(name: new_name)
    #   puts "Updated #{u.email} with #{u.name}"
    # end
    # User.reset_column_information
  end

  def down
    remove_column :users, :name
  end
end
