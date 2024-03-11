#!@shell@

echo "Removing current generated files"
[ -e ./gemset.nix ] && rm ./gemset.nix

echo "Regenerating gemset.nix"
@bundix@ --lock

echo "== Updating database =="
rails db:migrate

echo "== Removing old logs and tempfiles =="
rails log:clear tmp:clear

echo "== Restarting application server =="
rails restart

echo "Done"
