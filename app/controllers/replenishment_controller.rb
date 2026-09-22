# frozen_string_literal: true

# Forecast-driven replenishment dashboard and shortage allocation tool.
# See docs/replenishment.md for the method behind the numbers.
class ReplenishmentController < ApplicationController
  def index
    @settings = Replenishment::PlanService::Settings.from_params(params)
    @plan = Replenishment::PlanService.new(current_organization, settings: @settings)
    @rows = @plan.rows
    @summary = @plan.summary
  end

  def show
    @item = current_organization.items.find(params[:id])
    @settings = Replenishment::PlanService::Settings.from_params(params)
    @plan = Replenishment::PlanService.new(current_organization, settings: @settings)
    @row = @plan.rows.find { |r| r.item.id == @item.id }
    @months = @plan.history.month_labels
    @allocation = Replenishment::AllocationService.new(current_organization, @item, reserve: params[:reserve])
  end
end
