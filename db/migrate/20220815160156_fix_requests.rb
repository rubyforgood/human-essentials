class FixRequests < ActiveRecord::Migration[7.0]
  def change
    klass = Class.new(Partners::Base) do
      self.table_name = 'partner_users'
    end

    klass.all.each do |user|
      main_user = ::User.unscoped.find_by(email: user.email)
      ::Request.where(partner_user_id: user.id).
        update_all(partner_user_id: main_user.id, updated_at: Time.zone.now)
    end
  end
end
