# https://til.hashrocket.com/posts/chdlp2pbwb-delayed-job-queue-adapter-in-rspec-with-rails-51

class ActiveJob::QueueAdapters::DelayedJobAdapter
  class EnqueuedJobs
    def clear
      Delayed::Job.where(failed_at:nil).map &:destroy
    end
  end

  class PerformedJobs
    def clear
      Delayed::Job.where.not(failed_at:nil).map &:destroy
    end
  end

  def enqueued_jobs
    EnqueuedJobs.new
  end

  def performed_jobs
    PerformedJobs.new
  end
end
