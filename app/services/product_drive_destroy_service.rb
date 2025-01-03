class ProductDriveDestroyService
  def initialize(product_drive)
    @product_drive = product_drive
  end

  def call
    return false unless can_destroy?

    # Perform destruction logic
    @product_drive.destroy
  end

  private

  def can_destroy?
    if @product_drive.donations.empty?
      true
    else
      @product_drive.errors.add(:base, "Cannot delete product drive with donations.")
      false
    end
  end
end
