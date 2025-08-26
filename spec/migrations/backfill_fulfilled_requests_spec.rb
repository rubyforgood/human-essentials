require "rails_helper"
require Rails.root.join("db/migrate/20250826223940_backfill_fulfilled_requests")

RSpec.describe BackfillFulfilledRequests, type: :migration do
  let(:migration) { described_class.new }
  let(:organization) { create(:organization, :with_items) }
  let(:partner) { create(:partner, organization: organization) }

  it "updates started requests with complete distributions to fulfilled" do
    # Create a distribution with complete state
    distribution = create(:distribution, organization: organization, partner: partner, state: "complete")
    
    # Create a request with started status and link it to the distribution
    request = create(:request, :started, organization: organization, partner: partner, distribution: distribution)

    expect {
      migration.up
    }.to change { request.reload.status }.from("started").to("fulfilled")
  end

  it "does not change requests without complete distributions" do
    # Create a distribution with scheduled state (not complete)
    distribution = create(:distribution, organization: organization, partner: partner, state: "scheduled")
    
    # Create a request with started status and link it to the distribution
    request = create(:request, :started, organization: organization, partner: partner, distribution: distribution)

    expect {
      migration.up
    }.not_to change { request.reload.status }
  end

  it "does not change requests without any distribution" do
    # Create a request with started status but no distribution
    request = create(:request, :started, organization: organization, partner: partner, distribution: nil)

    expect {
      migration.up
    }.not_to change { request.reload.status }
  end

  it "does not change fulfilled requests even if they have complete distributions" do
    # Create a distribution with complete state
    distribution = create(:distribution, organization: organization, partner: partner, state: "complete")
    
    # Create a request that's already fulfilled
    request = create(:request, :fulfilled, organization: organization, partner: partner, distribution: distribution)

    expect {
      migration.up
    }.not_to change { request.reload.status }
  end

  it "does not change pending requests even if they have complete distributions" do
    # Create a distribution with complete state
    distribution = create(:distribution, organization: organization, partner: partner, state: "complete")
    
    # Create a request with pending status
    request = create(:request, :pending, organization: organization, partner: partner, distribution: distribution)

    expect {
      migration.up
    }.not_to change { request.reload.status }
  end
end
