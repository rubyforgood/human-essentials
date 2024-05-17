RUBY_VERSION="$(cat .ruby-version | tr -d '\n')"

# copy the file only if it doesn't already exist
cp -n .devcontainer/.env.codespaces .env

# If the project's required ruby version changes from 3.2.2, this command
# will download and compile the correct version, but it will take a long time.
if [ "$RUBY_VERSION" != "3.2.2" ]; then
  rvm install $RUBY_VERSION
  rvm use $RUBY_VERSION
  echo "Ruby $RUBY_VERSION installed"
fi

bin/setup
