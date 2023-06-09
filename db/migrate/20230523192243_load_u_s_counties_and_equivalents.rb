class LoadUSCountiesAndEquivalents < ActiveRecord::Migration[7.0]
  def up
    Rake::Task['db:load_us_counties'].invoke
  end

  def down
  end
end
