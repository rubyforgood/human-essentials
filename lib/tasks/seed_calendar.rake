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
      puts %(Remove them again with: Distribution.where(comment: "#{CalendarSeeder::MARKER}").destroy_all)
    end
  end
end
