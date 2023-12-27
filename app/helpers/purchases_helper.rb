# Encapsulates methods that need some business logic
module PurchasesHelper
  def purchased_from(purchase)
    purchase.purchased_from.nil? ? "" : "(#{purchase.purchased_from})"
  end
  
  def new_purchase_default_location(purchase)
    purchase.new_record? ? current_organization.intake_location : purchase.storage_location_id
  end
end
