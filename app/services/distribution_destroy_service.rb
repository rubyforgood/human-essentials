class DistributionDestroyService < DistributionService
  def initialize(distribution_id)
    @distribution_id = distribution_id
  end

  def call
    perform_distribution_service do
      DistributionDestroyEvent.publish(distribution)
      distribution.destroy!
      distribution.storage_location.increase_inventory(distribution.line_item_values)
    end
  end
end
