require_relative "page"

class DashboardPage
  include Page

  attr_reader :url_prefix

  def initialize(url_prefix:)
    @url_prefix = url_prefix
  end

  def path
    url_prefix + "/dashboard"
  end

  def has_add_donation_site_call_to_action?
    page.has_selector? "#org-stats-call-to-action-donation-sites"
  end

  def has_add_inventory_call_to_action?
    page.has_selector? "#org-stats-call-to-action-inventory"
  end

  def has_add_partner_call_to_action?
    page.has_selector? "#org-stats-call-to-action-partners"
  end

  def has_add_storage_location_call_to_action?
    page.has_selector? "#org-stats-call-to-action-storage-locations"
  end

  def has_getting_started_guide?
    page.has_selector? "#getting-started-guide"
  end
end
