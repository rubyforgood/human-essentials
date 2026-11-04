class DistributionCompleteService < DistributionService
  def initialize(distribution_id)
    @distribution_id = distribution_id
  end

  def call
    perform_distribution_service do
      raise "Distribution #{distribution_id} is already complete" if distribution.complete?

      DistributionCompleteEvent.publish(distribution)
      distribution.complete!
    end
  end
end
