RUBY_VERSION="$(cat .ruby-version | tr -d '\n')"

cp .devcontainer/.env.codespaces .env

# source /usr/local/rvm/scripts/rvm

# If the project's required ruby version changes from 3.2.2, this command
# will download and compile the correct version, but it will take a long time.
if [ "$RUBY_VERSION" != "3.2.2" ]; then
  rvm install $RUBY_VERSION
  rvm use $RUBY_VERSION
  echo "Ruby $RUBY_VERSION installed"
fi

bin/setup
