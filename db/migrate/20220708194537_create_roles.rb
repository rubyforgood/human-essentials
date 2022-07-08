class CreateRoles < ActiveRecord::Migration[7.0]
  def change

    # ignore password issues for now
    User.define_method(:password_required?) { false }

    User.all.each do |user|
      if user.super_admin?
        user.add_role(:super_admin)
      elsif user.organization_admin?
        user.add_role(:org_admin, user.organization)
      else
        user.add_role(:bank, user.organization)
      end
    end

    Partners::User.all.each do |user|
      begin
        main_user = ::User.unscoped.find_by(email: user.email)
        if main_user.nil?
          attrs = user.attributes.except('id').merge(discarded_at: nil)
          # null constraint on name for User table doesn't exist for Partner User table
          attrs['name'] ||= 'CHANGEME'
          main_user = ::User.create!(attrs)
        end
        main_user.add_role(:partner, user.partner)
      rescue
        puts user.attributes
        raise
      end
    end

  end
end
