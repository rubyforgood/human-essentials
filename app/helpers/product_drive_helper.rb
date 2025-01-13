module ProductDriveHelper
  def is_virtual(product_drive:)
    raise StandardError, 'No product drive was provided' if product_drive.blank?

    product_drive.virtual? ? 'Yes' : 'No'
  end

  def can_delete_product_drive?(user, product_drive)
    user.has_role?(Role::ORG_ADMIN, product_drive.organization) && product_drive.donations.empty?
  end
end
