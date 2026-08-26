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

      # PAST=1 also seeds last month, completed. Those records cannot be removed again -- see the
      # seeder -- so it is not the default.
      include_past = ENV["PAST"].present?
      created = CalendarSeeder.new(org, include_past: include_past).call

      puts "Seeded #{org.name}:"
      created[:by_month].sort.each { |month, count| puts "  #{month}  #{count}" }
      puts "  total #{created[:total]}"
      if created[:failures].any?
        puts "Skipped #{created[:failures].size}:"
        created[:failures].each { |reason| puts "  #{reason}" }
      end
      puts
      puts %(Remove them with: Distribution.where(comment: "#{CalendarSeeder::MARKER}").destroy_all)
      if include_past
        puts "  ...except the ones dated before today. A distribution a SnapshotEvent has already"
        puts "  folded into inventory cannot be destroyed, so the PAST group is permanent."
      else
        puts %(Add last month too, completed and permanent, with: PAST=1 bin/rails db:seed:calendar)
      end
    end
  end
end
