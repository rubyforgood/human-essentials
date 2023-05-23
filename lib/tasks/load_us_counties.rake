require 'csv'
namespace :db do
  desc "Load US Counties"
  task :load_us_counties => :environment do
      puts 'loading US counties and equivalents.  '
      counties = []
      CSV.foreach("lib//assets//us_county_and_equivalent_list.csv") do |row|
        if(row[2])
          counties<< {name: row[0], region: row[1].strip, category: row[2].strip}
        else
          counties<< {name: row[0], region: row[1].strip, category: "US_County"}
        end
      end
      County.upsert_all( counties, unique_by: [:name, :region])
  end
end