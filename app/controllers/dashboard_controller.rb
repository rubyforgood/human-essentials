# Prepares data to be shown to the users for their dashboard.
class DashboardController < ApplicationController
  respond_to :html, :js

  def index
    setup_date_range_picker
    @donations = current_organization.donations.includes(:line_items).during(helpers.selected_range)
    @recent_donations = @donations.recent
    @purchases = current_organization.purchases.includes(:line_items).during(helpers.selected_range)
    @recent_purchases = @purchases.recent
    @partner_agencies = current_organization.partners.during(helpers.selected_range)
    @total_agencies_types, @service_area = PartnerReporterService.partner_types_and_zipcodes(partners: @partner_agencies)

    @recent_distributions = current_organization.distributions.includes(:line_items).during(helpers.selected_range).recent
    if Flipper.enabled?(:itemized_distributions, current_user)
      @itemized_distributions = current_organization.distributions.includes(:line_items).during(helpers.selected_range)
      @onhand_quantities = current_organization.inventory_items.group("items.name").sum(:quantity)
      @onhand_minimums = current_organization.inventory_items
                                             .group("items.name")
                                             .maximum("items.on_hand_minimum_quantity")
    end
    @total_inventory = current_organization.total_inventory

    @org_stats = OrganizationStats.new(current_organization)

    # calling .recent on recent donations by manufacturers will only count the last 3 donations
    # which may not make sense when calculating total count using a date range
    @recent_donations_from_manufacturers = current_organization.donations.includes(:line_items).during(helpers.selected_range).by_source(:manufacturer)
    @top_manufacturers = current_organization.manufacturers.by_donation_count
  end
end
