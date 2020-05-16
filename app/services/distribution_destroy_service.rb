class DistributionDestroyService < DistributionService
  def initialize(distribution_id)
    @distribution_id = distribution_id
  end

  def call
    perform_distribution_service do
      distribution.destroy!
      distribution.storage_location.increase_inventory(distribution)
    end
  end
end
