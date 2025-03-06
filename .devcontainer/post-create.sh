RUBY_VERSION="$(cat .ruby-version | tr -d '\n')"

# copy the file only if it doesn't already exist
echo "*** Creating initial .env and vscode settings, if needed"
cp -n .devcontainer/.env.codespaces .env
mkdir -p .vscode && cp -n .devcontainer/launch.json.codespaces .vscode/launch.json

# If the project's required ruby version changes from 3.2.2, this command
# will download and compile the correct version, but it will take a long time.
if [ "$RUBY_VERSION" != "3.2.2" ]; then
  echo "*** Installing Ruby $RUBY_VERSION (this may take a while)"
  rvm install $RUBY_VERSION
  rvm use $RUBY_VERSION
  echo "Ruby $RUBY_VERSION installed"
fi

echo "*** Setting up node"
nvm install node

echo "*** Setting up ruby environment"
rbenv init bash
rbenv init zsh

# echo "*** Forcing platform version of nokogiri"
# gem install nokogiri -v 1.18.1 --platform=ruby -- --use-system-libraries

echo "*** Running project bin/setup"
bin/setup
