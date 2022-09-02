class StorageLocationDeactivateService
  include ServiceObjectErrorsMixin

  def initialize(storage_location)
    @storage_location = storage_location
  end

  def call
    raise Errors::StorageLocationNotEmpty unless valid?

    @storage_location.discard!

    self
  end

  private

  def valid?
    @storage_location.size <= 0
  end
end
