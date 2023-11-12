class CleanUpProfiles < ActiveRecord::Migration[7.0]
  def change
    Partners::Profile.
      left_joins(:partner).
      where(:partners => { id: nil}).
      delete_all
  end
end
