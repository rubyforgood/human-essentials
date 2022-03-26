class RemoveFkOnPartnerRequestsToUsers < ActiveRecord::Migration[6.1]
  def change
    # Remove FK to allow for step-by-step merging of DBs. This FK prevents PartnerRequests
    # being created since we aren't going to be creating Partner::Users in the partners DB
    # anymore
    remove_foreign_key :partner_requests, :users, column: :partner_user_id, primary_key: :id
  end
end
