#!@shell@

echo "Creating DB and running migrations. If this fails recheck your .env file and run 'setup-db'"
if [ ! -f .env ]; then
	echo "== Setup .env file from .env.example =="
	cp .env.example .env
fi

echo "== Preparing database =="
rails db:reset
rails db:test:prepare

echo "== Removing old logs, tempfiles, and jobs =="
rails log:clear tmp:clear jobs:clear

echo "== Restarting application server =="
rails restart

echo "== Precompiling assets =="
rails assets:precompile

echo "---------------------"
echo "❤️  Done! Run bin/start to run the application locally at http://localhost:3000 ❤️"
echo "[Note] It may take up to 5-10 seconds for the styles to compile, refresh after 10 seconds if the styles are looking unusual."
echo "---------------------"
