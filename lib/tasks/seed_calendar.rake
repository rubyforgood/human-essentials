namespace :db do
  namespace :seed do
    desc "Add distributions positioned for exercising the pick ups and deliveries calendar"
    task calendar: :environment do
      raise "Cannot run this in production" if Rails.env.production?

      require Rails.root.join("db/seeds/calendar_seeder")

      # `name`, not `short_name` -- there is no such column, and asking for one fails with a
      # PG::UndefinedColumn that names the query rather than the mistake.
      org = ENV["ORG"] ? Organization.find_by!(name: ENV["ORG"]) : Organization.first
      raise "No organization to seed. Run db:seed first." if org.nil?

      created = CalendarSeeder.new(org).call

      puts "Seeded #{org.name}:"
      created[:by_month].sort.each { |month, count| puts "  #{month}  #{count}" }
      puts "  total #{created[:total]}"
      if created[:failures].any?
        puts "Skipped #{created[:failures].size}:"
        created[:failures].each { |reason| puts "  #{reason}" }
      end
      puts
      puts "Remove them again with: bin/rails db:seed:calendar:clear"
    end

    namespace :calendar do
      desc "Remove what db:seed:calendar created, returning its stock to inventory"
      task clear: :environment do
        raise "Cannot run this in production" if Rails.env.production?

        require Rails.root.join("db/seeds/calendar_seeder")

        # Through DistributionDestroyService, not `destroy_all`. `Distribution` carries only
        # `before_destroy :check_no_intervening_snapshot`; nothing on the model publishes a
        # DistributionDestroyEvent, so `destroy_all` deletes the row and leaves its DistributionEvent
        # behind. Inventory then stays reduced for a distribution that no longer exists, and the
        # event is orphaned. Measured: 20 distributions holding 150 units, destroyed that way, moved
        # inventory by 0.
        removed = 0
        failed = []
        Distribution.where(comment: CalendarSeeder::MARKER).find_each do |distribution|
          result = DistributionDestroyService.new(distribution.id).call
          if result.success?
            removed += 1
          else
            failed << "#{distribution.id}: #{result.error}"
          end
        end

        puts "Removed #{removed}."
        failed.each { |line| puts "  could not remove #{line}" }
      end
    end
  end
end
