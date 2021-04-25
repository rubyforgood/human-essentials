if Rails.env.development? || Rails.env.test?
  module ActiveRecord
    module Tasks
      # Creates a Rake Task to drop databases
      class PostgreSQLDatabaseTasks
        def drop
          establish_master_connection
          database_name = configuration_hash[:database]
          connection.select_all "select pg_terminate_backend(pg_stat_activity.pid) from pg_stat_activity where datname='#{database_name}' AND state='idle';"
          connection.drop_database database_name
        end
      end
    end
  end
end
