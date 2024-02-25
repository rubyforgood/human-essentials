class PopulateNeededItems < ActiveRecord::Migration[7.0]
  def change
    Partners::Child.find_each do |child|
      child.needed_item_ids = [child.item_needed_diaperid] if child.item_needed_diaperid.present?
    end
  end
end
