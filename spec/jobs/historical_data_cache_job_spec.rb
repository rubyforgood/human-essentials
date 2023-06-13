require "rails_helper"

RSpec.describe HistoricalDataCacheJob, type: :job do
  include ActiveJob::TestHelper

  let(:organization) { create(:organization) }
  let(:type) { "Donation" }
  let(:job) { described_class.perform_later(org_id: organization.id, type: type) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(described_class)
      .with(org_id: organization.id, type: type)
      .on_queue("default")
  end

  it "caches the historical data" do
    expect(Rails.cache).to receive(:write).with("#{organization.short_name}-historical-#{type}-data", anything)
    perform_enqueued_jobs { job }
  end
end
