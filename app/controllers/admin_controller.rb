# [Super Admin] This is the parent controller for the Admin namespace, and also provides the Dashboard data for SuperAdmins.
class AdminController < ApplicationController
  before_action :require_admin

  def require_admin
    verboten! unless current_user.super_admin?
  end

  def dashboard
    @recent_organizations = Organization.where('created_at > ?', 1.week.ago)
    @recent_users = User.where('created_at > ?', 1.week.ago)
    @active_users = User.where('last_request_at > ?', 1.week.ago.utc).includes(:organization).order('organizations.name')
    @top_10_other = Item.by_partner_key('other').where.not(name: "Other").group(:name).limit(10).order('count_name DESC').count(:name)
    @donation_count = Donation.where('created_at > ?', 1.week.ago).count
    @distribution_count = Distribution.where('created_at > ?', 1.week.ago).count
    @request_count = Request.where('created_at > ?', 1.week.ago).count
    @organization_count = Organization.all.count
  end
end
