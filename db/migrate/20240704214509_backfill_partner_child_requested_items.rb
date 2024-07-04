class BackfillPartnerChildRequestedItems < ActiveRecord::Migration[7.1]
  def change
    Partners::Child.unscoped.where.not(item_needed_diaperid: nil).each do |child|
      child.requested_items << Item.find_by(id: child.item_needed_diaperid)
    end
  end
end
