class CleanupDelayedJobs < ActiveRecord::Migration[7.0]
  def change
    Delayed::Job.
      where(locked_at: nil, failed_at: nil).
      where("handler LIKE '%HistoricalDataCacheJob%'").delete_all
  end
end
