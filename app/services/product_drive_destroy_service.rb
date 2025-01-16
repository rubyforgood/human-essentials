class ProductDriveDestroyService
  class << self
    def call(product_drive, user, organization)
      return Result.new(error: "You are not allowed to perform this action.") unless verify_role(user, organization)
      return Result.new(error: "Cannot delete product drive with donations.") unless can_destroy?(product_drive, user)

      if product_drive.destroy
        Result.new(value: "Product drive was successfully destroyed.")
      else
        Result.new(error: product_drive.errors.full_messages.join("\n"))
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
