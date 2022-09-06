class FixRequests < ActiveRecord::Migration[7.0]
  def change
    klass = Class.new(Partners::Base) do
      self.table_name = 'partner_users'
    end

    #
    # Fix issue that caused requests to have the wrong associated user record.
    # This is the first part of the fixes to ensure the request as viewed by
    # Banks have the right partner user associated with it. 
    # Original migration that caused issues: db/migrate/20220716194537_merge_users.rb
    #
    # A second fix will be added to ensure Partners see the right requests on their
    # dashboard.
    #
    ::Request.where.not(partner_user_id: nil).where('created_at < ?', DateTime.new(2022, 8, 14, 15, 17)).each do |request|
      partner_user = klass.find(request.partner_user_id)
      main_user = ::User.unscoped.find_by(email: partner_user.email)
      request.update!(partner_user_id: main_user.id)
    end
  end
end
