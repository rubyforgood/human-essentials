# When you are using Capybara, you probably noticed that it starts the server on its own.
# That is done by starting your app server in a new thread.
# Since ActiveRecord has a connection pool thread-based,
# the server and the test suite are using different connections and transactions are not shared.
# This makes impossible for you to use transactional fixtures.
# This patch allows the connection to be shared,
# allowing you to use transactional fixtures once again.
# https://gist.github.com/josevalim/470808#gistcomment-5426
class ActiveRecord::Base
  mattr_accessor :shared_connection

  def self.connection
    shared_connection || retrieve_connection
  end
end

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection