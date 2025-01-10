class ProductDriveDestroyService
  attr_reader :product_drive, :user, :organization

  def initialize(product_drive, user, organization)
    @product_drive = product_drive
    @user = user
    @organization = organization
  end

  def self.call(product_drive, user, organization)
    new(product_drive, user, organization).call
  end

  def call
    return unauthorized_error unless verify_role
    return donation_error unless self.class.can_destroy?(product_drive, user)

    product_drive = organization.product_drives.find(product_drive.id)
    product_drive.destroy

    if product_drive.errors.any?
      {
        success: false,
        message: product_drive.errors.full_messages.join("\n")
      }
    else
      {
        success: true,
        message: "Product drive was successfully destroyed."
      }
    end
  end

  private

  def verify_role
    return true if user.has_role?(Role::ORG_ADMIN, @organization)
    false
  end

  def self.can_destroy?(product_drive, user)
    return false unless user.has_role?(Role::ORG_ADMIN, product_drive.organization)

    if product_drive.donations.empty?
      true
    else
      product_drive.errors.add(:base, "Cannot delete product drive with donations.")
      false
    end
  end

  def unauthorized_error
    {success: false, message: "You are not allowed to perform this action."}
  end

  def donation_error
    product_drive.errors.add(:base, "Cannot delete product drive with donations.")
    {success: false, message: "Cannot delete product drive with donations."}
  end
end
