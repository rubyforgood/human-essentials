class FixRequests < ActiveRecord::Migration[7.0]
  def change
    klass = Class.new(Partners::Base) do
      self.table_name = 'partner_users'
    end

    ::Request.where('created_at < "2022-08-14 15:17:00').each do |request|
      partner_user = klass.find(request.partner_user_id)
      main_user = ::User.unscoped.find_by(email: partner_user.email)
      request.update!(partner_user_id: main_user.id)
    end
    # Partners::Request.where('created_at < "2022-08-14 15:17:00').each do |request|
    #   partner_user = klass.find(request.partner_user_id)
    #   main_user = ::User.unscoped.find_by(email: partner_user.email)
    #   request.update!(partner_user_id: main_user.id)
    # end
  end
end
