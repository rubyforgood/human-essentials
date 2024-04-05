class HistoricalDataCacheJob < ApplicationJob
  def perform(org_id:, type:)
    organization = Organization.find_by(id: org_id)

    Rails.cache.write("#{organization.short_name}-historical-#{type}-data", HistoricalTrendService.new(organization.id, type).series)
  end

  def queue_name = "low_priority"
end
