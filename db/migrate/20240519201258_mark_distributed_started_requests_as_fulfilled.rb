class MarkDistributedStartedRequestsAsFulfilled < ActiveRecord::Migration[7.0]
  def up
    # Fix a data integrity issue; once a request has an associated
    # distribution created the request should be marked as fulfilled
    Request
      .where(status: :started)
      .where.not(distribution: nil)
      .update_all(status: :fulfilled)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
