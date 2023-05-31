class DeactiveUsers < ActiveRecord::Migration[7.0]
  def change
    Users.discarded.each do |user|
      user.add_role(:deactivated)
    end
  end
end
