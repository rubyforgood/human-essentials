# frozen_string_literal: true

namespace :replenishment do
  desc "DEVELOPMENT ONLY: add 24 months of synthetic distribution history so the planner has something to show"
  task demo_data: :environment do
    abort "Refusing to create synthetic data outside development" unless Rails.env.development?

    organization = Organization.first
    partners = organization.partners.to_a
    storage_location = organization.storage_locations.first
    rng = Random.new(2026)
    items = organization.items.active.where.not(reporting_category: nil).limit(8).to_a

    items.each_with_index do |item, index|
      base = rng.rand(300..1500)
      growth = [0.0, 0.01, 0.02, -0.005][index % 4]
      24.downto(1) do |months_ago|
        month = Date.current.beginning_of_month.months_ago(months_ago)
        seasonal = 1 + (0.15 * Math.sin(2 * Math::PI * month.month / 12.0))
        quantity = (base * ((1 + growth)**(24 - months_ago)) * seasonal * rng.rand(0.8..1.2)).round
        distribution = Distribution.create!(organization:, storage_location:, partner: partners.sample(random: rng),
          issued_at: month + rng.rand(0..27).days, delivery_method: :pick_up, state: :complete)
        distribution.line_items.create!(item:, quantity:)
      end
    end
    puts "Added synthetic history for #{items.map(&:name).join(", ")}"
  end

  desc "Backtest the demand forecaster against an organization's history. Usage: rake replenishment:backtest[ORG_ID,MONTHS]"
  task :backtest, %i[organization_id months] => :environment do |_task, args|
    organization = Organization.find(args[:organization_id] || Organization.first.id)
    months = (args[:months] || 24).to_i
    series = Replenishment::DemandHistory.new(organization, months:).series_by_item
    items = organization.items.where(id: series.keys).index_by(&:id)

    puts "Backtest for #{organization.name} (#{months} complete months of distributions)"
    puts "Item".ljust(41) + "Model".ljust(17) + "MAE".rjust(10) + " " + "Naive MAE".rjust(10) + " " + "Skill".rjust(8)

    results = series.filter_map do |item_id, history|
      next if history.count(&:positive?) < 6

      result = Replenishment::DemandForecaster.new(history).call
      next if result.mae.nil?

      puts format("%-40s %-16s %10.1f %10.1f %7.0f%%", items[item_id]&.name.to_s[0, 40], result.model,
        result.mae, result.naive_mae, (result.skill || 0) * 100)
      result
    end

    if results.any?
      total_mae = results.sum(&:mae)
      total_naive = results.sum(&:naive_mae)
      puts "-" * 88
      puts format("Overall: forecast error is %.0f%% lower than 'same as last month' across %d items",
        (1 - (total_mae / total_naive)) * 100, results.count)
    else
      puts "Not enough history to backtest (need 6+ months with demand per item)."
    end
  end
end
