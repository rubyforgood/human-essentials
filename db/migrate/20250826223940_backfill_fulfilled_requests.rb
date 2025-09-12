class BackfillFulfilledRequests < ActiveRecord::Migration[8.0]
  def up
    # This migration fixes requests that should be marked as "fulfilled" 
    # but are currently marked as "started"
    # A request should be "fulfilled" if its associated distribution is "complete"
    Request.joins(:distribution)
      .where(status: "started", distributions: { state: "complete" })
      .update_all(status: "fulfilled")
  end

  def down
    # This is a data correction migration, so we make it irreversible
    # to prevent accidental data corruption
    raise ActiveRecord::IrreversibleMigration
  end
end

# Migration Context:
# Previously, fulfilled requests could be incorrectly changed back to "started" status.
# This has been fixed in the Request model with validation, but this migration 
# corrects existing data that may be in an inconsistent state.
