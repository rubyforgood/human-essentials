RUBY_VERSION="$(cat .ruby-version | tr -d '\n')"

# copy the file only if it doesn't already exist
cp -n .devcontainer/.env.codespaces .env
mkdir -p .vscode && cp -n .devcontainer/launch.json.codespaces .vscode/launch.json

# If the project's required ruby version changes from 3.2.2, this command
# will download and compile the correct version, but it will take a long time.
if [ "$RUBY_VERSION" != "3.2.2" ]; then
  rvm install $RUBY_VERSION
  rvm use $RUBY_VERSION
  echo "Ruby $RUBY_VERSION installed"
fi

nvm install node
rbenv init bash
rbenv init zsh

bin/setup
