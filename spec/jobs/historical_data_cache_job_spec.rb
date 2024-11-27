RSpec.describe HistoricalDataCacheJob, type: :job do
  include ActiveJob::TestHelper

  let(:organization) { create(:organization) }
  let(:type) { "Donation" }
  let(:job) { described_class.perform_later(org_id: organization.id, type: type) }

  it "queues the job" do
    expect { job }.to have_enqueued_job(described_class)
      .with(org_id: organization.id, type: type)
      .on_queue("low_priority")
  end

  it "caches the historical data" do
    expected_data = {name: "Item 2", data: [0, 0, 0, 0, 0, 60, 0, 0, 30, 0, 0, 0], visible: false}
    allow_any_instance_of(HistoricalTrendService).to receive(:series).and_return(expected_data)

    perform_enqueued_jobs { job }

    cached_data = Rails.cache.read("#{organization.short_name}-historical-#{type}-data")
    expect(cached_data).to eq(expected_data)
  end
end
