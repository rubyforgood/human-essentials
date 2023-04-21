class FixBadUserRoles < ActiveRecord::Migration[7.0]
  def change
    bad_roles = Role.all.select { |r| r.resource_type && r.resource.nil? }

    bad_roles.each do |role|
      profile = Partners::Profile.find_by_id(role.resource_id)
      if profile.nil?
        next
      elsif profile.partner.nil?
        profile = Partners::Profile.find_by_id(profile.partner_id)
        next if profile.nil? || profile.partner.nil?
      end

      role.update!(resource_id: profile.partner_id)
    end

  end
end
