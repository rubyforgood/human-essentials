if Rails.env.development? || Rails.env.test?
  module ActiveRecord
    module Tasks
      # Creates a Rake Task to drop databases
      class PostgreSQLDatabaseTasks
        def drop
          establish_master_connection
          connection.select_all "select pg_terminate_backend(pg_stat_activity.pid) from pg_stat_activity where datname='#{configuration['database']}' AND state='idle';"
          connection.drop_database configuration['database']
        end
      end
    end
  end
end
