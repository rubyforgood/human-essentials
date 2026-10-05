# frozen_string_literal: true

# Forecast-driven replenishment report and shortage allocation tool.
# See docs/replenishment.md for the method behind the numbers.
#
# Two switches control access: the global `replenishment_planner` Flipper flag
# (so the feature can be shipped dark), and each bank's own
# `enable_replenishment_planner` setting on its organization settings page.
class ReplenishmentController < ApplicationController
  FEATURE_FLAG = "replenishment_planner"

  before_action :require_feature_enabled

  def self.available_for?(organization)
    Flipper.enabled?(FEATURE_FLAG) && organization&.enable_replenishment_planner?
  end

  def index
    @settings = Replenishment::PlanService::Settings.from_params(params, organization: current_organization)
    @plan = Replenishment::PlanService.new(current_organization, settings: @settings)
    @rows = @plan.rows
    @summary = @plan.summary
    @storage_locations = current_organization.storage_locations.active.alphabetized
  end

  def show
    @item = current_organization.items.find(params[:id])
    @settings = Replenishment::PlanService::Settings.from_params(params, organization: current_organization)
    @plan = Replenishment::PlanService.new(current_organization, settings: @settings)
    @row = @plan.rows.find { |r| r.item.id == @item.id }
    @months = @plan.history.month_labels
    @locations = Replenishment::LocationBreakdown.new(current_organization, @item).rows
    @allocation = Replenishment::AllocationService.new(current_organization, @item, reserve: params[:reserve])
  end

  private

  def require_feature_enabled
    raise ActionController::RoutingError, "Not Found" unless self.class.available_for?(current_organization)
  end
end
