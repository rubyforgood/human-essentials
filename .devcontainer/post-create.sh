# copy the file only if it doesn't already exist
echo "*** Creating initial .env and vscode settings, if needed"
cp -n .devcontainer/.env.codespaces .env
mkdir -p .vscode && cp -n .devcontainer/launch.json.codespaces .vscode/launch.json

echo "*** Setting up node"
nvm install node &

echo "*** Setting up ruby environment"
rbenv init bash &
rbenv init fish &
rbenv init zsh &

# echo "*** Forcing platform version of nokogiri"
# gem install nokogiri -v 1.18.1 --platform=ruby -- --use-system-libraries

# If the project's required ruby version (specified in .ruby-version)
# changes from 3.4.3, this command will download and compile the correct
# version, but it will take a long time.
echo "*** Installing rbenv-able Ruby ***"
rbenv install --skip-existing &

wait

# The post-checkout hook that records a rolled-back working tree. `.git/hooks` is not tracked, so
# the hooks live in `.githooks/` and git is pointed at them; this has to be re-run per clone.
echo "*** Pointing git at .githooks"
git config core.hooksPath .githooks

echo "*** Running project bin/setup"
bin/setup
