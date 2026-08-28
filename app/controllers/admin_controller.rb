# [Super Admin] This is the parent controller for the Admin namespace, and also provides the Dashboard data for SuperAdmins.
class AdminController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  before_action :require_admin
  skip_before_action :require_organization

  def require_admin
    verboten! unless current_user.has_cached_role?(Role::SUPER_ADMIN)
  end

  # The dashboard's "recently added" cards list at most RECENT_LIMIT rows.
  RECENT_LIMIT = 20

  def dashboard
    @recent_organizations = Organization.where('created_at > ?', 1.week.ago)
    @recent_users = User.where('created_at > ?', 1.week.ago).order(created_at: :desc).limit(RECENT_LIMIT)
    # Counted separately, and not off @recent_users: `.limit(20).count` returns the *cap*, so the
    # card reported "20 new users" whenever more than twenty had signed up in the week -- a page
    # size presented as a total. Same defect essentials_pagination_summary exists to avoid.
    @recent_users_total = User.where('created_at > ?', 1.week.ago).count
    @active_users = User.where('last_request_at > ?', 1.week.ago.utc).includes(:organization).order('organizations.name')
    @top_10_other = Item.by_partner_key('other').where.not(name: "Other").group(:name).limit(10).order('count_name DESC').count(:name)
    @donation_count = Donation.where('created_at > ?', 1.week.ago).count
    @distribution_count = Distribution.where('created_at > ?', 1.week.ago).count
    @request_count = Request.where('created_at > ?', 1.week.ago).count
    @organization_count = Organization.all.count
  end
end
