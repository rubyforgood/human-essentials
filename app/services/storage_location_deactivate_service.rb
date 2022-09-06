class StorageLocationDeactivateService
  include ServiceObjectErrorsMixin

  def initialize(storage_location:)
    @storage_location = storage_location
  end

  def call
    return false unless valid?

    @storage_location.discard!

    self
  end

  private

  def valid?
    @storage_location.size <= 0
  end
end
