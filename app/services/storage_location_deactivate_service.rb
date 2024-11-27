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
    if Event.read_events?(@storage_location.organization)
      inventory = View::Inventory.new(@storage_location.organization_id)
      inventory.quantity_for(storage_location: @storage_location.id) <= 0
    else
      @storage_location.size <= 0
    end
  end
end
