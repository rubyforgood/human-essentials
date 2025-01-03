module ProductDriveHelper
  def is_virtual(product_drive:)
    raise StandardError, 'No product drive was provided' if product_drive.blank?

    product_drive.virtual? ? 'Yes' : 'No'
  end
end
