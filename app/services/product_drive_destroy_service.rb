class ProductDriveDestroyService
  class << self
    def call(product_drive, user, organization)
      return Result.new(error: "You are not allowed to perform this action.") unless verify_role(user, organization)

      unless can_destroy?(product_drive, user)
        product_drive.errors.add(:base, "Cannot delete product drive with donations.")
        raise ActiveRecord::RecordInvalid.new(product_drive)
      end

      if product_drive.destroy
        Result.new(value: "Product drive was successfully destroyed.")
      else
        raise ActiveRecord::RecordNotDestroyed.new("Failed to destroy product drive", product_drive)
      end
    end

    def can_destroy?(product_drive, user)
      return false unless user.has_role?(Role::ORG_ADMIN, product_drive.organization)
      product_drive.donations.empty?
    end

    private

    def verify_role(user, organization)
      user.has_role?(Role::ORG_ADMIN, organization)
    end
  end
end
